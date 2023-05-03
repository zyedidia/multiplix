module plix.dev.uart.dwapb;

import core.volatile : vld, vst;
import bits = core.bits;

struct DwApbUart {
    struct Regs {
        uint io;
        uint ier;
        uint iir;
        uint lcr;
        uint mcr;
        uint lsr;
        uint msr;
        uint scratch;
        uint cntl;
        uint stat;
        uint baud;
    }

    Regs* uart;

    this(uintptr base) {
        uart = cast(Regs*) base;
    }

    void setup(uint baud) {}

    bool rx_empty() {
        return bits.get(vld(&uart.stat), 0) == 0;
    }

    uint rx_sz() {
        return bits.get(vld(&uart.stat), 19, 16);
    }

    bool can_tx() {
        return bits.get(vld(&uart.stat), 1) != 0;
    }

    ubyte rx() {
        // device_fence();
        while (rx_empty()) {
        }
        ubyte c = vld(&uart.io) & 0xff;
        // device_fence();
        return c;
    }

    void tx(ubyte c) {
        // device_fence();
        vst(&uart.io, c);
        // device_fence();
    }

    bool tx_empty() {
        // device_fence();
        return bits.get(vld(&uart.stat), 9) == 1;
    }

    void tx_flush() {
        while (!tx_empty()) {
        }
    }
}
