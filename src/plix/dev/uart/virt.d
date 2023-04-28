module plix.dev.uart.virt;

import core.volatile : vst;

struct Virt {
    struct Regs {
        uint thr;
    }

    Regs* regs;

    void setup(uint baud) {}

    void tx(ubyte b) {
        vst(&regs.thr, b);
    }

    ubyte rx() {
        return 0;
    }

    bool rx_empty() {
        return true;
    }
}
