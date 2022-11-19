module kernel.arch.riscv.start;

import kernel.arch.riscv.csr;
import kernel.arch.riscv.timer;
import kernel.arch.riscv.sbi;

import bits = ulib.bits;

void start(uint hartid, uintptr main) {
    // enable all kinds of interrupts
    csr_write!(Csr.sie)(csr_read!(Csr.sie) | (1UL << Sie.seie) | (1UL << Sie.stie) | (
            1UL << Sie.ssie));

    // call main
    (cast(void function(uint, uint)) main)(hartid, Hart.nharts());
}
