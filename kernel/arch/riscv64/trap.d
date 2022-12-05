module kernel.arch.riscv64.trap;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;
import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.cpu;

import kernel.cpu;
import kernel.proc;
import sys = kernel.sys;

import bits = ulib.bits;
import io = ulib.io;

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
    uintptr kgp;
    uintptr epc;
    Regs regs;
    Proc* p;
}

extern (C) {
    // userswitch in uservec.s
    extern void userswitch(Trapframe* tf, uintptr satp);
    // userret in uservec.s
    extern void userret(Trapframe* tf);
    // uservec in uservec.s
    extern void uservec();

    void usertrap(Trapframe* tf) {
        io.writeln("user trap");
        usertrapret(tf.p, false);
    }
}

void usertrapret(Proc* p, bool swtch) {
    Trap.disable();

    Csr.stvec = cast(uintptr)&uservec;

    // set up trapframe
    p.trapframe.ktp = cpuinfo.tls;
    p.trapframe.ksp = cpuinfo.stack + sys.pagesize;
    p.trapframe.kgp = getgp();

    Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.spp); // force return to usermode
    Csr.sstatus = bits.set(Csr.sstatus, Sstatus.spie); // enable interrupts in user mode

    Csr.sepc = p.trapframe.epc;

    if (swtch) {
        userswitch(p.trapframe, p.pt.satp(0));
    } else {
        userret(p.trapframe);
    }

    while (1) {}
}