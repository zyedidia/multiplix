module kernel.arch.riscv.trap;

import kernel.arch.riscv.csr;

import io = ulib.io;

extern (C) extern void trapvec();

void trap_init() {
    csr_write!(Csr.stvec)(cast(uintptr) &trapvec);
}

void trap_enable() {
    csr_write_bit!(Csr.sstatus)(Sstatus.sie, 1);
}

void trap_disable() {
    csr_write_bit!(Csr.sstatus)(Sstatus.sie, 0);
}

extern (C) void kerneltrap() {
    uintptr sepc = csr_read!(Csr.sepc)();
    uintptr sstatus = csr_read!(Csr.sstatus)();
    uintptr scause = csr_read!(Csr.scause)();

    /* io.writeln("[interrupt] sepc: ", cast(void*) sepc, ", sstatus: ", sstatus, ", scause: ", scause); */

    if (scause == Scause.si) {
        // acknowledge the interrupt by clearing ssip
        csr_write_bit!(Csr.sip)(Sip.ssip, 0);
    }
}

