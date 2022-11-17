module kernel.arch.riscv.start;

import kernel.arch.riscv.csr;
import kernel.arch.riscv.timer;

import bits = ulib.bits;

void start(uint hartid, uintptr main) {
    // enable all kinds of interrupts
    csr_write!(Csr.sie)(csr_read!(Csr.sie) | (1UL << Sie.seie) | (1UL << Sie.stie) | (
            1UL << Sie.ssie));

    // write the hartid to sscratch
    csr_write!(Csr.sscratch)(hartid);

    // call main
    (cast(void function()) main)();
}
