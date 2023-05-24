module plix.dev.uart.virt;

import core.volatile : vst;

struct Virt {
    struct Regs {
        ubyte thr;
    }

    Regs* regs;

    void setup(uint baud) {}

    void tx(ubyte b) {
        vst(&regs.thr, b);
    }

    void tx_flush() {}

    ubyte rx() {
        return 0;
    }

    bool rx_empty() {
        return true;
    }
}
