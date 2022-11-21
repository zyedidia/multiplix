module bootloader.main;

import core.volatile;

import kernel.sys;
import kernel.arch.riscv64.timer;
import arch = kernel.arch;
import crc = bootloader.crc32;

import ulib.memory;
import io = ulib.io;

extern (C) extern shared ubyte _kbss_start, _kbss_end;

extern (C) void dstart() {
    memset(cast(ubyte*) &_kbss_start, 0, &_kbss_end - &_kbss_start);
    boot();
}

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

void boot() {
    Uart.init();

    while (true) {
        putUint(BootFlags.GetProgInfo);
        Timer.delayTime(1000000);

        if (Uart.hasRxData() && getUint() == BootFlags.PutProgInfo) {
            break;
        }
    }

    ubyte* base = cast(ubyte*) getUint();
    uint nbytes = getUint();
    uint crc_recv = getUint();

    putUint(BootFlags.GetCode);
    putUint(crc_recv);

    if (getUint() != BootFlags.PutCode) {
        return;
    }

    for (uint i = 0; i < nbytes; i++) {
        ubyte c = Uart.rx();
        volatileStore(&base[i], c);
    }
    uint crc_calc = crc.crc32(base, nbytes);
    if (crc_calc != crc_recv) {
        putUint(BootFlags.BadCodeCksum);
        return;
    }
    putUint(BootFlags.BootSuccess);
    Uart.flushTx();

    arch.fencei();

    // call the loaded program
    auto fn = cast(void function()) base;
    fn();

    while (1) {}
}

extern (C) {
    void ulib_tx(ubyte c) {
        Uart.tx(c);
    }
    void ulib_exit() {}
}
