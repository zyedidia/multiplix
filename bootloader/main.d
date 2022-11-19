module bootloader.main;

import core.volatile;

import timer = kernel.arch.riscv.timer;
import uart = kernel.uart;
import crc = bootloader.crc32;

import ulib.memory;

extern (C) extern __gshared uint _kbss_start, _kbss_end;

extern (C) void dstart(uint hartid) {
    uint* bss = &_kbss_start;
    uint* bss_end = &_kbss_end;

    while (bss < bss_end) {
        volatileStore(bss++, 0);
    }

    boot();
}

enum BootFlags {
    BootStart = 0xFFFF0000,

    GetProgInfo = 0x11112222,
    PutProgInfo = 0x33334444,

    GetCode = 0x55556666,
    PutCode = 0x77778888,

    BootSuccess = 0x9999AAAA,
    BootError = 0xBBBBCCCC,

    BadCodeAddr = 0xdeadbeef,
    BadCodeCksum = 0xfeedface,
}

uint get_uint() {
    union recv {
        ubyte[4] b;
        uint i;
    }

    recv x;
    x.b[0] = uart.rx();
    x.b[1] = uart.rx();
    x.b[2] = uart.rx();
    x.b[3] = uart.rx();
    return x.i;
}

void put_uint(uint u) {
    uart.tx((u >> 0) & 0xff);
    uart.tx((u >> 8) & 0xff);
    uart.tx((u >> 16) & 0xff);
    uart.tx((u >> 24) & 0xff);
}

extern (C) extern __gshared ubyte _kheap_start;

extern (C) extern shared ubyte __start_copyin;
extern (C) extern shared ubyte __stop_copyin;

void boot() {
    while (true) {
        put_uint(BootFlags.GetProgInfo);
        import kernel.arch.riscv.timer : delay_time;
        delay_time(1000000);
        if (!uart.rx_empty() && get_uint() == BootFlags.PutProgInfo) {
            break;
        }
    }

    ubyte* base = cast(ubyte*) get_uint();
    uint nbytes = get_uint();
    uint crc_recv = get_uint();

    put_uint(BootFlags.GetCode);
    put_uint(crc_recv);

    if (get_uint() != BootFlags.PutCode) {
        return;
    }

    for (uint i = 0; i < nbytes; i++) {
        ubyte c = uart.rx();
        volatileStore(&base[i], c);
    }
    uint crc_calc = crc.crc32(base, nbytes);
    if (crc_calc != crc_recv) {
        put_uint(BootFlags.BadCodeCksum);
        return;
    }
    put_uint(BootFlags.BootSuccess);
    uart.tx_flush();

    // call the loaded program
    auto fn = cast(void function()) base;
    fn();
}

extern (C) {
    void ulib_tx(ubyte c) {
        uart.tx(c);
    }
    void ulib_exit() {}
}
