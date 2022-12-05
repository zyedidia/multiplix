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

uintptr getgp() {
    import ldc.llvmasm;
    return __asm!uintptr(
        "mv $0, gp", "=r"
    );
}

import kernel.arch.riscv64.sbi;

/* extern (C) extern ubyte _bootentry_pa; */
// TODO: don't hardcode this
enum _bootentry_pa = 0x84010000;

void startCore(uint hartid) {
    Hart.start(hartid, cast(uintptr) _bootentry_pa, 0);
}