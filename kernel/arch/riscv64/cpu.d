module kernel.arch.riscv64.cpu;

void fence() {
    asm {
        "fence";
    }
}

void fencei() {
    asm {
        "fence.i";
    }
}

void fencevma() {
    asm {
        "sfence.vma";
    }
}

void wait() {
    asm {
        "wfi";
    }
}

void setTlsBase(void* base) {
    asm {
        "mv tp, %0" : : "r" (base);
    }
}
