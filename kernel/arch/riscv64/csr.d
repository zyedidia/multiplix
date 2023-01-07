module kernel.arch.riscv64.csr;

enum CsrNum {
    mvendorid = 0xF11,
    marchid = 0xF12,
    mhartid = 0xF14,
    mstatus = 0x300,
    misa = 0x301,
    medeleg = 0x302,
    mideleg = 0x303,
    mie = 0x304,
    mtvec = 0x305,
    mcounteren = 0x306,
    mscratch = 0x340,
    mepc = 0x341,
    mcause = 0x342,
    mtval = 0x343,
    mip = 0x344,

    pmpcfg0 = 0x3A0,
    pmpaddr0 = 0x3B0,

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

    cycle = 0xc00,
    time = 0xc01,
    cycleh = 0xc80,
    timeh = 0xc81,
}

enum Priv {
    u = 0b00,
    s = 0b01,
    m = 0b11,
}

enum Mstatus {
    sie = 1,
    mie = 3,
    mpie = 7,
}

enum Sstatus {
    sie = 1,
    spie = 5,
    spp = 8,
    sum = 18,
}

enum Mip {
    stip = 5,
    mtip = 7,
}

enum Sip {
    ssip = 1,
}

enum Mie {
    stie = 5,
    mtie = 7,
}

enum Sie {
    seie = 9,
    stie = 5,
    ssie = 1,
}

enum Cause {
    // interrupts
    // software timer interrupt
    sti = 0x8000000000000005UL,
    // machine timer interrupt
    mti = 0x8000000000000007UL,

    // exceptions
    breakpoint = 3,
    ecall_s = 9,
    ecall_m = 11,
}

// dfmt off
template GenCsr(string name) {
    const char[] GenCsr = `@property static uintptr ` ~ name ~ `() {
        return rdcsr!(CsrNum.` ~ name ~ `)();
    }
    @property static void ` ~ name ~ `(uintptr v) {
        wrcsr!(CsrNum.` ~ name ~ `)(v);
    }`;
}
// dfmt on

struct Csr {
    mixin(GenCsr!("mstatus"));
    mixin(GenCsr!("mvendorid"));
    mixin(GenCsr!("marchid"));
    mixin(GenCsr!("mhartid"));
    mixin(GenCsr!("mtvec"));
    mixin(GenCsr!("mcounteren"));
    mixin(GenCsr!("misa"));
    mixin(GenCsr!("medeleg"));
    mixin(GenCsr!("mideleg"));
    mixin(GenCsr!("mie"));
    mixin(GenCsr!("mcause"));
    mixin(GenCsr!("mscratch"));
    mixin(GenCsr!("mepc"));
    mixin(GenCsr!("mtval"));
    mixin(GenCsr!("mip"));

    mixin(GenCsr!("pmpcfg0"));
    mixin(GenCsr!("pmpaddr0"));

    mixin(GenCsr!("stvec"));
    mixin(GenCsr!("satp"));
    mixin(GenCsr!("sie"));
    mixin(GenCsr!("sepc"));
    mixin(GenCsr!("sscratch"));
    mixin(GenCsr!("sstatus"));
    mixin(GenCsr!("scause"));

    mixin(GenCsr!("time"));
    mixin(GenCsr!("cycle"));
}

void wrcsr(CsrNum reg)(uintptr val) {
    asm {
        "csrw %0, %1" :  : "i"(reg), "r"(val);
    }
}

void wrcsr(CsrNum reg, int val)() if (val < 32) {
    asm {
        "csrwi %0, %1" :  : "i"(reg), "I"(val);
    }
}

uintptr rdcsr(CsrNum reg)() {
    uintptr r;
    asm {
        "csrr %0, %1" : "=r"(r) : "i"(reg);
    }
    return r;
}

