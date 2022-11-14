module kernel.arch.riscv.csr;

// A common interface for accessing RISC-V CSRs.

enum Reg {
    mcycle = 0xb00,
    mcycleh = 0xb80,
}

void write(Reg reg)(uintptr val) {
    asm {
        "csrw %0, %1" : : "i"(reg), "r"(val);
    }
}

void write(Reg reg, int val)() if (val < 32) {
    asm {
        "csrwi %0, %1" : : "i"(reg), "I"(val);
    }
}

uintptr read(Reg reg)() {
    uintptr r;
    asm {
        "csrr %0, %1" : "=r"(r) : "i"(reg);
    }
    return r;
}
