module kernel.arch.riscv64.trap;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;
import kernel.arch.riscv64.regs;

import kernel.cpu;
import kernel.proc;
import sys = kernel.sys;

import bits = ulib.bits;

extern (C) extern void kernelvec();

struct Trap {
    static void init() {
        Csr.stvec = cast(uintptr)&kernelvec;
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
    import io = ulib.io;

    uintptr sepc = Csr.sepc;
    uintptr scause = Csr.scause;

    io.writeln("[interrupt] sepc: ", cast(void*) sepc);

    if (scause == Scause.sti) {
        Timer.intr(Timer.interval);
    }
}

struct Trapframe {
    uintptr ktp;
    uintptr ksp;
    uintptr epc;
}

// userret in uservec.s
extern (C) extern void userresume(Regs* regs, uintptr satp);
// uservec in uservec.s
extern (C) extern void uservec();

void usertrapret(Proc* p) {
    Trap.disable();

    Csr.stvec = cast(uintptr)&uservec;

    // set up trapframe
    p.trapframe.ktp = cpuinfo.tls;
    p.trapframe.ksp = cpuinfo.stack + sys.pagesize;

    Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.spp); // force return to usermode
    Csr.sstatus = bits.set(Csr.sstatus, Sstatus.spie); // enable interrupts in user mode

    Csr.sepc = p.trapframe.epc;

    userresume(&p.regs, p.pt.satp(0));

    while (1) {}
}
