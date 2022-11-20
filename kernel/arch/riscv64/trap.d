module kernel.arch.riscv64.trap;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;

import bits = ulib.bits;

extern (C) extern void kernelvec();

struct Trap {
    static void init() {
        Csr.stvec = cast(uintptr) &kernelvec;
    }

    static void enable() {
        Csr.sstatus = bits.set(Csr.sstatus, Sstatus.sie);
    }

    static void disable() {
        Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.sie);
    }
}

extern (C) void kerneltrap() {
    import io = ulib.io;

    uintptr sepc = Csr.sepc;
    uintptr scause = Csr.scause;

    io.writeln("[interrupt] sepc: ", cast(void*) sepc);

    if (scause == Scause.sti) {
        Timer.intr(Timer.interval);
    }
}
