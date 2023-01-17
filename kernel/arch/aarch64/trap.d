module kernel.arch.aarch64.trap;

import core.sync;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.timer;

import kernel.proc;
import kernel.cpu;

import io = ulib.io;
import bits = ulib.bits;

extern (C) extern void kernelvec();

struct Trap {
    static void setup() {
        SysReg.vbar_el1 = cast(uintptr) &kernelvec;
    }

    // TODO: use daifset and daifclr instead
    // enable/disble fiq and irq
    static void enable() {
        // setting a bit to 0 unmasks (enables) the irq
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b1100);
    }

    static void disable() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b1111);
    }

    static bool enabled() {
        return ((SysReg.daif >> 6) & 0b11) != 0;
    }
}

extern (C) void kernel_exception(Regs* regs) {
    io.writeln("kernel exception");
}

extern (C) void kernel_interrupt(Regs* regs) {
    import kernel.cpu;
    io.writeln("core: ", cpuinfo.coreid, ", kernel interrupt");
    Timer.intr();
}

struct Trapframe {
    uintptr sp;
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
        io.writeln("usertrap");
        while (1) {}
        /* usertrapret(tf.p, false); */
    }
}

void usertrapret(Proc* p, bool swtch) {
    Trap.disable();

    // return to el0 aarch64 with no interrupts masked
    SysReg.spsr_el1 = 0b0000_0_0_0000;

    // set up trapframe
    p.trapframe.sp = cpuinfo.stack;

    // set elr to p.trapframe.epc
    SysReg.elr_el1 = p.trapframe.epc;

    if (swtch) {
        SysReg.ttbr0_el1 = cast(uintptr) p.pt;
        vm_fence();
    }

    import io = ulib.io;
    io.writeln("going to userret");

    userret(p.trapframe);

    while (1) {}
}
