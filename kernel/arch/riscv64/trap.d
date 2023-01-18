module kernel.arch.riscv64.trap;

import core.sync;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;
import kernel.arch.riscv64.regs;

import kernel.proc;
import kernel.cpu;

import sys = kernel.sys;

import bits = ulib.bits;
import io = ulib.io;

extern (C) extern void kernelvec();

struct Trap {
    static void setup() {
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

struct Trapframe {
    uintptr ktp;
    uintptr ksp;
    uintptr kgp;
    uintptr epc;
    Regs regs;
    Proc* p;
}

extern (C) {
    // userret in uservec.s
    extern noreturn userret(Trapframe* tf);
    // uservec in uservec.s
    extern void uservec();

    noreturn usertrap(Trapframe* tf) {
        uintptr scause = Csr.scause;

        io.writeln("usertrap: scause: ", cast(void*) scause);

        if (scause == Cause.ecall_u) {
            tf.epc = Csr.sepc + 4;
        } else if (scause == Cause.sti) {
            Timer.intr(Timer.interval);
        } else {
            assert(0, "unhandled user trap");
        }

        usertrapret(tf.p, false);
    }
}

noreturn usertrapret(Proc* p, bool swtch) {
    Trap.disable();

    Csr.stvec = cast(uintptr) &uservec;

    // set up trapframe
    p.trapframe.ktp = cpuinfo.tls;
    p.trapframe.ksp = cpuinfo.stack;
    p.trapframe.kgp = rd_gp();

    Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.spp); // force return to usermode
    Csr.sstatus = bits.set(Csr.sstatus, Sstatus.spie); // enable interrupts in user mode

    Csr.sepc = p.trapframe.epc;

    if (swtch) {
        Csr.satp = p.pt.satp(0);
        vm_fence();
    }

    userret(p.trapframe);
}
