module kernel.arch.riscv.start;

import kernel.arch.riscv.csr;
import kernel.arch.riscv.timer;

import bits = ulib.bits;

void start(uintptr main) {
    // change privilege to supervisor mode after mret
    csr_write_bits!(Csr.mstatus)(Mstatus.mpp_hi, Mstatus.mpp_lo, Mstatus.mode_s);

    // jump to main after the mret
    csr_write!(Csr.mepc)(main);

    // make sure paging is disabled
    csr_write!(Csr.satp)(0);

    // delegate all interrupts and exceptions to supervisor mode
    csr_write!(Csr.medeleg)(0xffff);
    csr_write!(Csr.mideleg)(0xffff);
    csr_write!(Csr.sie)(read!(Csr.sie) | (1UL << Sie.seie) | (1UL << Sie.stie) | (1UL << Sie.ssie));

    csr_write!(Csr.pmpaddr0)(0x3fffffffffffffUL);
    csr_write!(Csr.pmpcfg0)(0xf);

    timer_irq_init();

    asm {
        "mret";
    }

    while (true) {}
}
