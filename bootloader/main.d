module bootloader.main;

import core.volatile;
import core.sync;

import kernel.board : Uart;
import kernel.timer : Timer;

import crc = ulib.crc32;
import io = ulib.io;

import ulib.memory;

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

    ulong getUlong() {
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

    uint getUint() {
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

    void putUint(uint u) {
        Uart.tx((u >> 0) & 0xff);
        Uart.tx((u >> 8) & 0xff);
        Uart.tx((u >> 16) & 0xff);
        Uart.tx((u >> 24) & 0xff);
    }

    BootData recv() {
        Uart.init(115200);

        while (true) {
            putUint(BootFlags.GetProgInfo);
            Timer.delay_cycles(100000000);

            if (!Uart.rx_empty() && getUint() == BootFlags.PutProgInfo) {
                break;
            }
        }

        ubyte* base = &_kheap_start;
        ulong entry = getUlong();
        uint nbytes = getUint();
        uint crc_recv = getUint();

        putUint(BootFlags.GetCode);
        putUint(crc_recv);

        if (getUint() != BootFlags.PutCode) {
            putUint(BootFlags.BootError);
            while (1) {}
        }
        for (uint i = 0; i < nbytes; i++) {
            base[i] = Uart.rx();
        }
        uint crc_calc = crc.crc32(base, nbytes);
        if (crc_calc != crc_recv) {
            putUint(BootFlags.BadCodeCksum);
            while (1) {}
        }
        putUint(BootFlags.BootSuccess);

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

extern (C) void kmain() {
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

    size_t nbytes = boot.data.length;

    while (overlaps(new_copyin, copyin_size, boot.entry, nbytes) ||
            overlaps(new_copyin, copyin_size, &boot.data[0], nbytes)) {
        new_copyin += nbytes + (nbytes % 16);
    }

    memcpy(new_copyin, cast(ubyte*)&copyin, copyin_size);

    insn_fence();

    // call the new copyin that has been moved
    auto fn = cast(void function(ubyte*, ubyte[])) new_copyin;
    fn(boot.entry, boot.data);

    while (1) {
    }
}

import ldc.attributes;

@(section("copyin")) void copyin(ubyte* dst, ubyte[] src) {
    for (uint i = 0; i < src.length; i++) {
        volatileStore(&dst[i], src[i]);
    }
    insn_fence();
    auto main = cast(void function()) dst;
    main();
}
@(section("copyin2")) void copyin2(ubyte* dst, ubyte[] src) {
    for (uint i = 0; i < src.length; i++) {
        volatileStore(&dst[i], src[i]);
    }
    insn_fence();
    auto main = cast(void function()) dst;
    main();
}
