module plix.arch.riscv64.trap;

import bits = core.bits;

import plix.arch.riscv64.csr : csr, Sstatus;
import plix.proc : Proc;

struct irq {
    static void set_handler(void function() handler) {
        csr.stvec = cast(uintptr) &handler;
    }

    static void on() {
        csr.sstatus_set!(Sstatus.sie)();
    }

    static void off() {
        csr.sstatus_clear!(Sstatus.sie)();
    }

    static bool enabled() {
        return bits.get(csr.sstatus, Sstatus.sie) == 1;
    }
}

extern (C) void kerneltrap() {
}

extern (C) {
    extern noreturn userret(Proc* p);
    extern void uservec();
}

extern (C) noreturn usertrap(Proc* p) {
    assert(false);
}

noreturn usertrapret(Proc* p) {
    assert(false);
}
