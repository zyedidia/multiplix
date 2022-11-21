module kernel.arch.riscv64.csr;

enum CsrNum {
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

enum Sstatus {
    sie = 1,
}

enum Sip {
    ssip = 1,
}

enum Sie {
    seie = 9,
    stie = 5,
    ssie = 1,
}

enum Scause {
    // software timer interrupt
    sti = 0x8000000000000005UL,
}

// dfmt off
template GenCsr(string name) {
    const char[] GenCsr = "@property static uintptr " ~ name ~ "() {" ~
        "return rdcsr!(CsrNum." ~ name ~ ")();" ~
    "}\n" ~
    "@property static void " ~ name ~ "(uintptr v) {" ~
        "wrcsr!(CsrNum." ~ name ~ ")(v);" ~
    "}\n";
}
// dfmt on

struct Csr {
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
