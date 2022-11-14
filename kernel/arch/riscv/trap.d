module kernel.arch.riscv.trap;

import kernel.arch.riscv.csr;

import io = ulib.io;

extern (C) extern void trapvec();

void init() {
    write!(Reg.stvec)(cast(uintptr) &trapvec);
}

void enable() {
    writeBit!(Reg.sstatus)(Sstatus.sie, 1);
}

void disable() {
    writeBit!(Reg.sstatus)(Sstatus.sie, 0);
}

extern (C) void kerneltrap() {
    uintptr sepc = read!(Reg.sepc)();
    uintptr sstatus = read!(Reg.sstatus)();
    uintptr scause = read!(Reg.scause)();

    io.writeln("[interrupt] sepc: ", cast(void*) sepc, ", sstatus: ", sstatus, ", scause: ", scause);

    if (scause == Scause.si) {
        // acknowledge the interrupt by clearing ssip
        writeBit!(Reg.sip)(Sip.ssip, 0);
    }
}
