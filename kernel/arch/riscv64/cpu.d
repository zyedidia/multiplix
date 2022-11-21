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
        "mv tp, %0" :  : "r"(base);
    }
}

import kernel.arch.riscv64.sbi;

/* extern (C) extern ubyte _bootentry_pa; */
enum _bootentry_pa = 0x84010000;

void startAllCores() {
    auto n = Hart.nharts();
    for (uint i = 0; i < n; i++) {
        Hart.start(i, cast(uintptr) _bootentry_pa, 0);
    }
}
