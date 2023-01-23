module kernel.arch.aarch64.trap;

import core.sync;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.timer;

import kernel.proc;
import kernel.cpu;
import kernel.syscall;

import vm = kernel.vm;

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
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0100);
    }

    static void disable() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0111);
    }

    static bool enabled() {
        return ((SysReg.daif >> 6) & 0b11) != 0;
    }
}

extern (C) void kernel_exception(Regs* regs) {
    const auto exc_class = bits.get(SysReg.esr_el1, 31, 26);
    io.writeln("elr: ", cast(void*) SysReg.elr_el1);
    io.writeln("kernel exception: ", cast(void*) exc_class);
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
    // userret in uservec.s
    extern noreturn userret(Trapframe* tf);
    // uservec in uservec.s
    extern void uservec();

    noreturn user_interrupt(Trapframe* tf) {
        import kernel.cpu;
        /* io.writeln("core: ", cpuinfo.coreid, ", user interrupt"); */
        Timer.intr();
        import kernel.schedule;
        schedule();
    }

    noreturn user_exception(Trapframe* tf) {
        const auto exc_class = bits.get(SysReg.esr_el1, 31, 26);
        /* io.writeln("usertrap: ", cast(void*) exc_class, " elr: ", cast(void*) SysReg.elr_el1); */
        /* io.writeln("far_el1: ", cast(void*) SysReg.far_el1); */

        switch (exc_class) {
            case Exception.svc:
                Regs* r = &tf.regs;
                r.x0 = syscall_handler(tf.p, r.x7, r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6);
                break;
            default:
                break;
        }

        usertrapret(tf.p, false);
    }
}

noreturn usertrapret(Proc* p, bool swtch) {
    Trap.disable();

    // return to el0 aarch64 with no interrupts masked
    SysReg.spsr_el1 = 0b0000_0_0_0000;

    // set up trapframe
    p.trapframe.sp = cpuinfo.stack;

    // set elr to p.trapframe.epc
    SysReg.elr_el1 = p.trapframe.epc;

    if (swtch) {
        SysReg.ttbr0_el1 = vm.ka2pa(cast(uintptr) p.pt);
        vm_fence();
    }

    userret(p.trapframe);
}
