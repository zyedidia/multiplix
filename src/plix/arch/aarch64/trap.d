module plix.arch.aarch64.trap;

import plix.arch.aarch64.regs : Regs;

struct Irq {
    static void set_handler(void function() handler) {
    }

    static void on() {
    }

    static void off() {
    }

    static bool enabled() {
        return false;
    }
}

struct Trapframe {
    uintptr sp;
    uintptr epc;
    uintptr tp;
    Regs regs;
}
