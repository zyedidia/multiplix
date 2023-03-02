module kernel.arch.riscv64.tls;

import kernel.cpu;

Cpu* rd_cpu() {
    Cpu* cpu;
    asm {
        "mv %0, tp" : "=r"(cpu);
    }
    return cpu;
}

void wr_cpu(Cpu* cpu) {
    asm {
        "mv tp, %0" : : "r"(cpu);
    }
}
