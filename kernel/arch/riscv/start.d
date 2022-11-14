module kernel.arch.riscv.start;

import kernel.arch.riscv.csr;
import bits = ulib.bits;
import timer = kernel.arch.riscv.timer;

void start(uintptr main) {
    // change privilege to supervisor mode after mret
    writeBits!(Reg.mstatus)(Mstatus.mpp_hi, Mstatus.mpp_lo, Mstatus.mode_s);

    // jump to main after the mret
    write!(Reg.mepc)(main);

    // make sure paging is disabled
    write!(Reg.satp)(0);

    // delegate all interrupts and exceptions to supervisor mode
    write!(Reg.medeleg)(0xffff);
    write!(Reg.mideleg)(0xffff);
    write!(Reg.sie)(read!(Reg.sie) | (1UL << Sie.seie) | (1UL << Sie.stie) | (1UL << Sie.ssie));

    write!(Reg.pmpaddr0)(0x3fffffffffffffUL);
    write!(Reg.pmpcfg0)(0xf);

    timer.irqinit();

    asm {
        "mret";
    }

    while (true) {}
}
