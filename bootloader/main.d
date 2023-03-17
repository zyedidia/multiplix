module bootloader.main;

import core.volatile;
import core.sync;

import kernel.board : Uart;
import kernel.timer : Timer;

import arch = kernel.arch;

import crc = ulib.crc32;

import libc;

__gshared bool primary = true;

struct BootData {
    ubyte* entry;
    ubyte[] data;
}

struct Payload {
	ulong entry;
	uint size;
	uint cksum;
    ubyte[0] data;
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
        while (true) {
            put_uint(BootFlags.GetProgInfo);
            Timer.delay_us(100 * 1000); // delay 100ms

            if (!Uart.rx_empty() && get_uint() == BootFlags.PutProgInfo) {
                break;
            }
        }

        ubyte* base = heap;
        const ulong entry = get_ulong();
        const uint nbytes = get_uint();
        const uint crc_recv = get_uint();

        put_uint(BootFlags.GetCode);
        put_uint(crc_recv);

        if (get_uint() != BootFlags.PutCode) {
            put_uint(BootFlags.BootError);
            _halt();
        }
        for (uint i = 0; i < nbytes; i++) {
            base[i] = Uart.rx();
        }
        const uint crc_calc = crc.crc32(base, nbytes);
        if (crc_calc != crc_recv) {
            put_uint(BootFlags.BadCodeCksum);
            _halt();
        }
        put_uint(BootFlags.BootSuccess);
        Uart.tx_flush();

        return BootData(cast(ubyte*) entry, base[0 .. nbytes]);
    }
} else {
    extern (C) extern __gshared Payload payload;
    extern (C) extern __gshared int payload_size;

    BootData unpack() {
        import ulib.crc32;
        ubyte* entry = cast(ubyte*)payload.entry;
        uint length = cast(uint)payload.size;
        assert(length == payload_size - Payload.sizeof);
        assert(payload.cksum == crc32(payload.data.ptr, length));
        return BootData(entry, payload.data.ptr[0..length]);
    }
}

__gshared BootData bootdat;

extern (C) noreturn kmain(int coreid, ubyte* heap) {
    arch.monitor_init();

    arch.enter_kernel();

    // We are booting the kernel, so enable virtual memory.
    arch.kernel_setup(primary);

    if (!primary) {
        // Secondary core can jump directly to the entry because the primary
        // core already copied the payload there.
        insn_fence();
        auto fn = cast(noreturn function(int)) bootdat.entry;
        fn(coreid);
    }

    version (uart) {
        BootData boot = recv(heap);
    } else {
        BootData boot = unpack();
    }
    bootdat = boot;

    primary = false;

    // write backwards in case the target region overlaps the payload region
    assert(boot.entry >= boot.data.ptr && boot.data.length > 0);
    for (long i = cast(long) boot.data.length - 1; i >= 0; i--) {
        vst(boot.entry + i, boot.data[i]);
    }
    sync_idmem(boot.entry, boot.data.length);
    auto main = cast(noreturn function(int)) boot.entry;
    main(coreid);
}
