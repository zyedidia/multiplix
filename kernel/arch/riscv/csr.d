module kernel.arch.riscv.csr;

import bits = ulib.bits;

enum Csr {
    mhartid = 0xf14,
    mstatus = 0x300,
    medeleg = 0x302,
    mideleg = 0x303,
    mie = 0x304,
    mtvec = 0x305,
    mscratch = 0x340,
    mepc = 0x341,
    mcycle = 0xb00,
    mcycleh = 0xb80,

    sstatus = 0x100,
    sedeleg = 0x102,
    sideleg = 0x103,
    sie = 0x104,
    stvec = 0x105,
    sscratch = 0x140,
    sepc = 0x141,
    scause = 0x142,
    stval = 0x143,
    sip = 0x144,
    satp = 0x180,

    pmpaddr0 = 0x3b0,
    pmpcfg0 = 0x3a0,
}

enum Mstatus {
    mpp_hi = 12,
    mpp_lo = 11,

    mie = 3,

    mode_u = 0b00,
    mode_s = 0b01,
    mode_m = 0b11,
}

enum Sstatus {
    sie = 1,
}

enum Mie {
    mtie = 7,
}

enum Sie {
    seie = 9,
    stie = 5,
    ssie = 1,
}

enum Sip {
    ssip = 1,
}

enum Scause {
    // software interrupt
    si = 0x8000000000000001UL,
}

enum Satp {
    off = 0,
    sv39 = 8,
    sv48 = 9,
    sv57 = 10,
    sv64 = 11,
}

void csr_write(Csr reg)(uintptr val) {
    asm {
        "csrw %0, %1" : : "i"(reg), "r"(val);
    }
}

void csr_write(Csr reg, int val)() if (val < 32) {
    asm {
        "csrwi %0, %1" : : "i"(reg), "I"(val);
    }
}

void csr_write_bit(Csr reg)(uint bit, uint val) {
    uintptr rd = csr_read!reg();
    csr_write!reg(bits.set(rd, bit, val));
}

void csr_write_bits(Csr reg)(uint hi, uint lo, ulong val) {
    uintptr rd = csr_read!reg();
    csr_write!reg(bits.set(rd, hi, lo, val));
}

uintptr csr_read(Csr reg)() {
    uintptr r;
    asm {
        "csrr %0, %1" : "=r"(r) : "i"(reg);
    }
    return r;
}
