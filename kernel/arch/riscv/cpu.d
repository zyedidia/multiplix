module kernel.arch.riscv.cpu;

void dsb() {
    asm {
        "fence";
    }
}
