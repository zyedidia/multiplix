module plix.arch.riscv64.trap;

import bits = core.bits;

import plix.arch.riscv64.csr : Csr, Sstatus, Cause;
import plix.arch.riscv64.regs : Regs, rdtp, rdgp;
import plix.arch.riscv64.cache : vm_fence;
import plix.proc : Proc;
import plix.cpu : cpu;
import plix.trap : irq_handler, pgflt_handler, unhandled, IrqType, FaultType;
import plix.syscall : syscall_handler;

struct Irq {
    static void setup() {
        Csr.stvec = cast(uintptr) &kernelvec;
    }

    static void on() {
        Csr.sstatus_set!(Sstatus.sie)();
    }

    static void off() {
        Csr.sstatus_clear!(Sstatus.sie)();
    }

    static bool enabled() {
        return bits.get(Csr.sstatus, Sstatus.sie) == 1;
    }
}

extern (C) void kerneltrap() {
    auto sepc = Csr.sepc;
    auto scause = Csr.scause;

    if (scause == Cause.sti) {
        irq_handler(IrqType.timer);
    } else {
        import core.exception : panicf;
        panicf("[unhandled kerneltrap]: core: %u, cause: %lx, epc: %lx, mtval: %lx\n", cpu.id, scause, sepc, Csr.stval);
    }
}

struct Trapframe {
    uintptr ktp;
    uintptr ksp;
    uintptr kgp;
    uintptr epc;
    Regs regs;
}

extern (C) {
    // userret in uservec.s
    extern noreturn userret(Proc* p);
    // uservec in uservec.s
    extern void uservec();
    // kernelvec in kernel.s
    extern void kernelvec();
}

extern (C) noreturn usertrap(Proc* p) {
    uintptr scause = Csr.scause;
    Csr.stvec = cast(uintptr) &kernelvec;

    switch (scause) {
    case Cause.ecall_u:
        p.trapframe.epc = Csr.sepc + 4;
        Regs* r = &p.trapframe.regs;
        r.a0 = syscall_handler(p, r.a7, r.a0, r.a1, r.a2, r.a3, r.a4, r.a5, r.a6);
        break;
    case Cause.sti:
        irq_handler(p, IrqType.timer);
        break;
    case Cause.wpgflt:
        pgflt_handler(p, cast(void*) Csr.stval, FaultType.write);
        break;
    default:
        import plix.print : println;
        println("[unhandled usertrap] epc: ", cast(void*) Csr.sepc, " cause: ", scause);
        unhandled(p);
    }

    usertrapret(p);
}

noreturn usertrapret(Proc* p) {
    Irq.off();

    Csr.stvec = cast(uintptr) &uservec;

    // set up trapframe
    p.trapframe.ktp = rdtp();
    p.trapframe.ksp = p.kstackp();
    p.trapframe.kgp = rdgp();
    Csr.sscratch = cast(uintptr) p;

    Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.spp); // force return to usermode
    Csr.sstatus = bits.set(Csr.sstatus, Sstatus.spie);  // enable interrupts in user mode

    Csr.sepc = p.trapframe.epc;

    Csr.satp = p.pt.satp(0);
    vm_fence();

    userret(p);
}
