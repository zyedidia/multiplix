module kernel.arch.riscv64.csr;

// dfmt off
const char[] GenCsr(string name) =
`static uintptr ` ~ name ~ `() {
    uintptr r;
    asm {
        "csrr %0, ` ~ name ~ `" : "=r"(r);
    }
    return r;
}
static void ` ~ name ~ `(uintptr v) {
    asm {
        "csrw ` ~ name ~ `, %0" :: "r"(v);
    }
}`;
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

    mixin(GenCsr!("tselect"));
    mixin(GenCsr!("tdata1"));
    mixin(GenCsr!("tdata2"));

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
    illegal = 2,
    breakpoint = 3,
    ecall_u = 8,
    ecall_s = 9,
    ecall_m = 11,
}
