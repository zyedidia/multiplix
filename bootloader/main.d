module bootloader.main;

import core.volatile;
import core.sync;

import kernel.board : Uart;
import kernel.timer : Timer;

import arch = kernel.arch;

import crc = ulib.crc32;
import io = ulib.io;

import ulib.memory;

__gshared bool primary = true;

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

    BootData recv(ubyte* heap) {
        Uart.init(115200);

        while (true) {
            put_uint(BootFlags.GetProgInfo);
            Timer.delay_us(100 * 1000); // delay 100ms

            if (!Uart.rx_empty() && get_uint() == BootFlags.PutProgInfo) {
                break;
            }
        }

        ubyte* base = heap;
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

__gshared BootData bootdat;

extern (C) void kmain(int coreid, ubyte* heap) {
    arch.monitor_init();

    version (kenter) {
        arch.enter_kernel();
    }

    version (kboot) {
        // We are booting the kernel, so enable virtual memory.
        arch.kernel_setup(primary);
    }

    if (!primary) {
        // Secondary core can jump directly to the entry because the primary
        // core already copied the payload there.
        insn_fence();
        auto fn = cast(void function(int)) bootdat.entry;
        fn(coreid);
        return;
    }

    version (uart) {
        BootData boot = recv(heap);
    } else {
        BootData boot = unpack();
    }
    bootdat = boot;

    primary = false;

    for (uint i = 0; i < boot.data.length; i++) {
        volatile_st(boot.entry + i, boot.data[i]);
    }
    insn_fence();
    auto main = cast(void function(int)) boot.entry;
    main(coreid);
}
