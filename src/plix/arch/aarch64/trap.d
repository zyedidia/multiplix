module plix.arch.aarch64.trap;

import plix.arch.aarch64.regs : Regs;
import plix.arch.aarch64.cache : vm_fence;
import plix.arch.aarch64.sysreg : SysReg, Exception, Spsr;
import plix.trap : irq_handler, IrqType, unhandled, pgflt_handler, FaultType;
import plix.syscall : syscall_handler;
import plix.proc : Proc;
import plix.vm : ka2pa;

import bits = core.bits;

struct Irq {
    static void set_handler(void function() handler) {
        SysReg.vbar_el1 = cast(uintptr) &kernelvec;
    }

    static void on() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0000);
    }

    static void off() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b1111);
    }

    static bool enabled() {
        return ((SysReg.daif >> 6) & 0b11) != 0b11;
    }
}

extern (C) void kernel_exception(Regs* regs) {
    import core.exception : panicf;
    const auto exc_class = bits.get(SysReg.esr_el1, 31, 26);
    panicf("[unhandled kernel exception] esr: %lx, elr: %lx\n", exc_class, SysReg.elr_el1);
}

extern (C) void kernel_interrupt(Regs* regs) {
    irq_handler(IrqType.timer);
}

struct Trapframe {
    uintptr sp;
    uintptr epc;
    uintptr tp;
    Regs regs;
}

extern (C) {
    // userret in uservec.s
    extern noreturn userret(Proc* p);
    // uservec in uservec.s
    extern void uservec();
    // kernelvec in kernelvec.s
    extern void kernelvec();
}

extern (C) noreturn user_interrupt(Proc* p) {
    irq_handler(p, IrqType.timer);
    // TODO: yield process
    usertrapret(p);
}

extern (C) noreturn user_exception(Proc* p) {
    const auto exc_class = bits.get(SysReg.esr_el1, 31, 26);

    switch (exc_class) {
    case Exception.svc:
        Regs* r = &p.trapframe.regs;
        r.x0 = syscall_handler(p, r.x7, r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6);
        break;
    case Exception.data_abort_lower:
        ubyte direction = SysReg.esr_el1 & 1;
        pgflt_handler(p, cast(void*) SysReg.far_el1, direction == 1 ? FaultType.write : FaultType.read);
        break;
    default:
        import plix.print : printf;
        printf("[unhandled user exception] esr: %lx, elr: %lx\n", exc_class, SysReg.elr_el1);
        unhandled(p);
    }

    usertrapret(p);
}

noreturn usertrapret(Proc* p) {
    Irq.off();

    // return to el0 aarch64 with no interrupts masked
    SysReg.spsr_el1 = Spsr.el0;

    // set up trapframe
    p.trapframe.sp = p.kstackp();
    p.trapframe.tp = SysReg.tpidr_el1;

    // set elr to p.trapframe.epc
    SysReg.elr_el1 = p.trapframe.epc;

    SysReg.ttbr0_el1 = ka2pa(cast(uintptr) p.pt);
    vm_fence();

    userret(p);
}
