module plix.arch.riscv64.cpu;

void wfi() {
    asm {
        "wfi" ::: "memory";
    }
}

pragma(inline, true)
usize rdcpu() {
    usize cpu;
    asm {
        "mv %0, tp" : "=r"(cpu);
    }
    return cpu;
}

void wrcpu(usize cpu) {
    asm {
        "mv tp, %0" : : "r"(cpu);
    }
}
