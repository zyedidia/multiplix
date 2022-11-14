module kernel.arch.riscv.timer;

import csr = kernel.arch.riscv.csr;
import sys = kernel.sys;

void init() {
}

uint cycles() {
    return cast(uint) csr.read!(csr.Reg.mcycle)();
}

void delay_us(uint us) {
    uint rb = cycles();
    while (1) {
        uint ra = cycles();
        if ((ra - rb) >= us * (sys.core_freq / (1000 * 1000))) {
            break;
        }
    }
}
