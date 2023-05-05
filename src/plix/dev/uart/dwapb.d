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

    enum Lsr {
        dr = 0,   // data ready (receiver has data)
        temt = 6, // transmitter empty
        thre = 5, // transmit holding register empty
    }

    Regs* uart;

    this(uintptr base) {
        uart = cast(Regs*) base;
    }

    void setup(uint baud) {}

    bool rx_empty() {
        return !bits.get(vld(&uart.lsr), Lsr.dr);
    }

    ubyte rx() {
        while (rx_empty()) {
        }
        ubyte c = vld(&uart.io) & 0xff;
        return c;
    }

    void tx(ubyte c) {
        while (!tx_empty()) {
        }
        vst(&uart.io, c);
    }

    bool tx_empty() {
        return bits.get(vld(&uart.lsr), Lsr.thre) != 0;
    }

    void tx_flush() {
        while (!tx_empty()) {
        }
    }
}
