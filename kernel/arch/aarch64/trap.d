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

struct ArchTrap {
    static void setup() {
        SysReg.vbar_el1 = cast(uintptr) &kernelvec;
    }

    // TODO: use daifset and daifclr instead
    // enable/disble fiq and irq
    static void on() {
        // setting a bit to 0 unmasks (enables) the irq
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0000);
    }

    static void off() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0111);
    }

    static bool is_on() {
        return ((SysReg.daif >> 6) & 0b11) != 0b11;
    }
}

extern (C) void kernel_exception(Regs* regs) {
    import core.exception;

    const auto exc_class = bits.get(SysReg.esr_el1, 31, 26);
    panic("[unhandled kernel exception] esr: ", Hex(exc_class), " elr: ", cast(void*) SysReg.elr_el1);
}

extern (C) void kernel_interrupt(Regs* regs) {
    import kernel.irq;
    Irq.handler();
    ArchTimer.intr();
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

    noreturn user_interrupt(Proc* p) {
        import kernel.irq;
        Irq.handler();

        ArchTimer.intr();
        p.yield();
        usertrapret(p);
    }

    noreturn user_exception(Proc* p) {
        const auto exc_class = bits.get(SysReg.esr_el1, 31, 26);

        switch (exc_class) {
            case Exception.svc:
                Regs* r = &p.trapframe.regs;
                r.x0 = syscall_handler(p, r.x7, r.x0, r.x1, r.x2, r.x3, r.x4, r.x5, r.x6);
                break;
            default:
                import core.exception;
                panic("[unhandled user exception] esr: ", Hex(exc_class), " elr: ", cast(void*) SysReg.elr_el1);
                break;
        }

        usertrapret(p);
    }
}

noreturn usertrapret(Proc* p) {
    ArchTrap.off();

    // return to el0 aarch64 with no interrupts masked
    SysReg.spsr_el1 = Spsr.el0;

    // set up trapframe
    p.trapframe.sp = p.kstackp();
    p.trapframe.tp = SysReg.tpidr_el1;

    // set elr to p.trapframe.epc
    SysReg.elr_el1 = p.trapframe.epc;

    SysReg.ttbr0_el1 = vm.ka2pa(cast(uintptr) p.pt);
    vm_fence();

    userret(p);
}
