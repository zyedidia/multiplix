module arch.riscv.cpu;

void dsb() {
    asm {
        "fence";
    }
}
