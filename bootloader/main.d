module bootloader.main;

import core.volatile;
import core.sync;

import kernel.board : Uart;
import kernel.timer : Timer;
import kernel.spinlock;

import arch = kernel.arch;

import crc = ulib.crc32;
import io = ulib.io;

import ulib.memory;

__gshared bool primary = true;
shared Spinlock bootlock;

extern (C) {
    extern shared ubyte __start_copyin, __stop_copyin;
    extern shared ubyte __start_copyin2, __stop_copyin2;
    extern __gshared ubyte _kheap_start;
}

struct BootData {
    ubyte* entry;
    ubyte[] data;
}

version (uart) {
    enum BootFlags {
        BootStart = 0xFFFF0000,

        GetProgInfo = 0x11223344,
        PutProgInfo = 0x33334444,

        GetCode = 0x55556666,
        PutCode = 0x77778888,

        BootSuccess = 0x9999AAAA,
        BootError = 0xBBBBCCCC,

        BadCodeAddr = 0xdeadbeef,
        BadCodeCksum = 0xfeedface,
    }

    ulong get_ulong() {
        union recv {
            ubyte[8] b;
            ulong i;
        }

        recv x;
        x.b[0] = Uart.rx();
        x.b[1] = Uart.rx();
        x.b[2] = Uart.rx();
        x.b[3] = Uart.rx();
        x.b[4] = Uart.rx();
        x.b[5] = Uart.rx();
        x.b[6] = Uart.rx();
        x.b[7] = Uart.rx();
        return x.i;
    }

    uint get_uint() {
        union recv {
            ubyte[4] b;
            uint i;
        }

        recv x;
        x.b[0] = Uart.rx();
        x.b[1] = Uart.rx();
        x.b[2] = Uart.rx();
        x.b[3] = Uart.rx();
        return x.i;
    }

    void put_uint(uint u) {
        Uart.tx((u >> 0) & 0xff);
        Uart.tx((u >> 8) & 0xff);
        Uart.tx((u >> 16) & 0xff);
        Uart.tx((u >> 24) & 0xff);
    }

    BootData recv() {
        Uart.init(115200);

        while (true) {
            put_uint(BootFlags.GetProgInfo);
            Timer.delay_us(100 * 1000); // delay 100ms

            if (!Uart.rx_empty() && get_uint() == BootFlags.PutProgInfo) {
                break;
            }
        }

        ubyte* base = &_kheap_start;
        ulong entry = get_ulong();
        uint nbytes = get_uint();
        uint crc_recv = get_uint();

        put_uint(BootFlags.GetCode);
        put_uint(crc_recv);

        if (get_uint() != BootFlags.PutCode) {
            put_uint(BootFlags.BootError);
            while (1) {}
        }
        for (uint i = 0; i < nbytes; i++) {
            base[i] = Uart.rx();
        }
        uint crc_calc = crc.crc32(base, nbytes);
        if (crc_calc != crc_recv) {
            put_uint(BootFlags.BadCodeCksum);
            while (1) {}
        }
        put_uint(BootFlags.BootSuccess);

        return BootData(cast(ubyte*) entry, base[0 .. nbytes]);
    }
} else {
    extern (C) extern __gshared ubyte payload;
    extern (C) extern __gshared int payload_size;

    BootData unpack() {
        ubyte* entry = (cast(ubyte**) &payload)[0];
        return BootData(entry, (&payload)[8 .. payload_size]);
    }
}

bool overlaps(ubyte* d1, size_t sz1, ubyte* d2, size_t sz2) {
    // (StartA <= EndB) and (EndA >= StartB)
    return d1 < d2 + sz2 && d2 < d1 + sz1;
}

extern (C) void kmain(int coreid) {
    arch.monitor_init();

    bootlock.lock();
    version (kenter) {
        arch.enter_kernel();
    }

    // move copyin to a new location, which cannot overlap with [entry,
    // entry+nbytes) or [boot.data, boot.data+nbytes) or the stack
    ubyte* new_copyin = &_kheap_start;
    size_t copyin_size = &__stop_copyin - &__start_copyin;
    size_t copyin2_size = &__stop_copyin2 - &__start_copyin2;

    assert(copyin_size == copyin2_size, "copyin is not PIC (size mismatch)");
    assert(memcmp(&copyin, &copyin2, copyin_size) == 0, "copyin is not PIC (code mismatch)");

    version (uart) {
        BootData boot = recv();
    } else {
        BootData boot = unpack();
    }

    version (kboot) {
        // We are booting the kernel, so enable virtual memory.
        arch.kernel_setup(primary);
        import vm = kernel.vm;
        // Entry is a high kernel address, so convert it to the physical
        // address for checking overlap.
        auto phys_entry = cast(ubyte*) vm.kpa2pa(cast(uintptr) boot.entry);
    } else {
        auto phys_entry = boot.entry;
    }

    if (!primary) {
        // Secondary core can jump directly to the entry because the primary
        // core already copied the payload there.
        insn_fence();
        bootlock.unlock();
        auto fn = cast(void function(int)) boot.entry;
        fn(coreid);
        while (1) {}
    }

    /* primary = false; */
    /*  */
    /* for (uint i = 0; i < boot.data.length; i++) { */
    /*     volatile_st(boot.entry + i, boot.data[i]); */
    /* } */
    /* insn_fence(); */
    /* bootlock.unlock(); */
    /* auto main = cast(void function(int)) boot.entry; */
    /* main(coreid); */

    size_t nbytes = boot.data.length;

    while (overlaps(new_copyin, copyin_size, phys_entry, nbytes) ||
            overlaps(new_copyin, copyin_size, &boot.data[0], nbytes)) {
        new_copyin += nbytes + (nbytes % 16);
    }

    memcpy(new_copyin, cast(ubyte*)&copyin, copyin_size);
    insn_fence();

    // done booting the primary core, all further cores will be secondary
    primary = false;

    // call the new copyin that has been moved
    auto copyfn = cast(void function(void delegate() shared, ubyte*, ubyte[], int)) new_copyin;
    copyfn(&bootlock.unlock, boot.entry, boot.data, coreid);

    while (1) {}
}

import ldc.attributes;

@(section("copyin")) void copyin(void delegate() shared unlock, ubyte* dst, ubyte[] src, int coreid) {
    for (uint i = 0; i < src.length; i++) {
        volatile_st(&dst[i], src[i]);
    }
    insn_fence();
    unlock();
    auto main = cast(void function(int)) dst;
    main(coreid);
}
@(section("copyin2")) void copyin2(void delegate() shared unlock, ubyte* dst, ubyte[] src, int coreid) {
    for (uint i = 0; i < src.length; i++) {
        volatile_st(&dst[i], src[i]);
    }
    insn_fence();
    unlock();
    auto main = cast(void function(int)) dst;
    main(coreid);
}
