module plix.arch.riscv64.cpu;

pragma(inline, true)
void wfi() {
    asm {
        "wfi" ::: "memory";
    }
}

pragma(inline, true)
void sev() {
    // riscv does not have sev
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

extern (C) noreturn _halt() {
    while (1) {
        wfi();
    }
}
