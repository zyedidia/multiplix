module kernel.arch.riscv.timer;

import core.volatile;

import kernel.arch.riscv.csr;
import sys = kernel.sys;
import sbi = kernel.arch.riscv.sbi;

ulong timer_time() {
    return csr_read!(Csr.time)();
}

ulong timer_cycles() {
    return csr_read!(Csr.cycle)();
}

void timer_irq_init() {
    ulong interval = 1000000;
    ulong next_time = timer_time() + interval;
    sbi.Timer.set_timer(next_time);
}
