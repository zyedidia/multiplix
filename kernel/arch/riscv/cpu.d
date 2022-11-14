module kernel.arch.riscv.cpu;

void fence() {
    asm {
        "fence";
    }
}
