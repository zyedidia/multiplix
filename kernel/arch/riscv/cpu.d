module kernel.arch.riscv.cpu;

void fence() {
    asm {
        "fence";
    }
}

void sfence_vma() {
    asm {
        "sfence.vma zero, zero";
    }
}
