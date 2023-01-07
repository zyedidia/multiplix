module kernel.arch.riscv64.trap;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;

import bits = ulib.bits;
import io = ulib.io;

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

    static bool enabled() {
        return bits.get(Csr.sstatus, Sstatus.sie);
    }
}

extern (C) void kerneltrap() {
    auto sepc = Csr.sepc;
    auto scause = Csr.scause;

    io.writeln("[trap] sepc: ", cast(void*) sepc);

    if (scause == Cause.sti) {
        Timer.intr(Timer.interval);
    }
}
