module kernel.arch.riscv64.trap;

import core.sync;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.timer;
import kernel.arch.riscv64.regs;

import kernel.proc;
import kernel.cpu;
import kernel.syscall;

import bits = ulib.bits;
import io = ulib.io;

extern (C) extern void kernelvec();

struct ArchTrap {
    static void setup() {
        Csr.stvec = cast(uintptr) &kernelvec;
    }

    static void on() {
        Csr.sstatus = bits.set(Csr.sstatus, Sstatus.sie);
    }

    static void off() {
        Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.sie);
    }

    static bool is_on() {
        return bits.get(Csr.sstatus, Sstatus.sie) == 1;
    }
}

extern (C) void kerneltrap() {
    auto sepc = Csr.sepc;
    auto scause = Csr.scause;

    io.writeln("[trap] sepc: ", cast(void*) sepc, " cause: ", Hex(scause));

    if (scause == Cause.sti) {
        ArchTimer.intr();
    } else {
        import core.exception;
        panic("[unhandled kernel trap] epc: ", cast(void*) sepc, " cause: ", Hex(scause));
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

    noreturn usertrap(Proc* p) {
        uintptr scause = Csr.scause;

        // io.writeln("usertrap: scause: ", cast(void*) scause, " epc: ", cast(void*) Csr.sepc);
        Csr.stvec = cast(uintptr) &kernelvec;

        if (scause == Cause.ecall_u) {
            p.trapframe.epc = Csr.sepc + 4;
            Regs* r = &p.trapframe.regs;
            r.a0 = syscall_handler(p, r.a7, r.a0, r.a1, r.a2, r.a3, r.a4, r.a5, r.a6);
        } else if (scause == Cause.sti) {
            ArchTimer.intr();
            assert(0, "TODO: schedule");
        } else {
            import core.exception;
            panic("unhandled user trap");
        }

        usertrapret(p, false);
    }
}

noreturn usertrapret(Proc* p, bool swtch) {
    ArchTrap.off();

    Csr.stvec = cast(uintptr) &uservec;

    // set up trapframe
    p.trapframe.ktp = cpuinfo.tls;
    p.trapframe.ksp = p.kstackp();
    p.trapframe.kgp = rd_gp();
    Csr.sscratch = cast(uintptr) p;

    Csr.sstatus = bits.clear(Csr.sstatus, Sstatus.spp); // force return to usermode
    Csr.sstatus = bits.set(Csr.sstatus, Sstatus.spie); // enable interrupts in user mode

    Csr.sepc = p.trapframe.epc;

    if (swtch) {
        Csr.satp = p.pt.satp(0);
        vm_fence();
    }

    userret(p);
}
