module kernel.arch.aarch64.sysreg;

// dfmt off
const char[] GenSysReg(string name) = GenSysRegRdOnly!(name) ~ GenSysRegWrOnly!(name);
const char[] GenSysRegRdOnly(string name) =
`pragma(inline, true) ` ~
`static uintptr ` ~ name ~ `() {
    uintptr val;
    asm {
        "mrs %0, ` ~ name ~ `" : "=r"(val);
    }
    return val;
}`;
const char[] GenSysRegWrOnly(string name) =
`pragma(inline, true) ` ~
`static void ` ~ name ~ `(uintptr v) {
    asm {
        "msr ` ~ name ~ `, %0" : : "r"(v);
    }
}`;
// dfmt on

struct SysReg {
    mixin(GenSysRegRdOnly!("currentel"));

    mixin(GenSysReg!("elr_el3"));
    mixin(GenSysReg!("spsr_el3"));
    mixin(GenSysReg!("scr_el3"));
    mixin(GenSysReg!("vbar_el3"));
    mixin(GenSysReg!("esr_el3"));
    mixin(GenSysReg!("cptr_el3"));

    mixin(GenSysReg!("sctlr_el2"));
    mixin(GenSysReg!("spsr_el2"));
    mixin(GenSysReg!("hcr_el2"));
    mixin(GenSysReg!("tpidr_el2"));
    mixin(GenSysReg!("vbar_el2"));
    mixin(GenSysReg!("esr_el2"));
    mixin(GenSysReg!("elr_el2"));
    mixin(GenSysReg!("mdcr_el2"));
    mixin(GenSysReg!("ttbr0_el2"));
    mixin(GenSysReg!("tcr_el2"));
    mixin(GenSysReg!("cptr_el2"));
    mixin(GenSysReg!("mair_el2"));
    mixin(GenSysReg!("far_el2"));

    mixin(GenSysReg!("sctlr_el1"));
    mixin(GenSysReg!("sp_el1"));
    mixin(GenSysReg!("ttbr0_el1"));
    mixin(GenSysReg!("ttbr1_el1"));
    mixin(GenSysReg!("tcr_el1"));
    mixin(GenSysReg!("mair_el1"));
    mixin(GenSysReg!("tpidr_el1"));
    mixin(GenSysReg!("vbar_el1"));
    mixin(GenSysReg!("elr_el1"));
    mixin(GenSysReg!("spsr_el1"));
    mixin(GenSysReg!("esr_el1"));
    mixin(GenSysReg!("far_el1"));
    mixin(GenSysReg!("mdscr_el1"));
    mixin(GenSysRegRdOnly!("mpidr_el1"));
    mixin(GenSysRegWrOnly!("oslar_el1"));
    mixin(GenSysReg!("cpacr_el1"));

    mixin(GenSysReg!("dbgbcr0_el1"));
    mixin(GenSysReg!("dbgbvr0_el1"));
    mixin(GenSysReg!("dbgwcr0_el1"));
    mixin(GenSysReg!("dbgwvr0_el1"));

    mixin(GenSysReg!("cntfrq_el0"));
    mixin(GenSysRegRdOnly!("cntpct_el0"));
    mixin(GenSysReg!("cntp_ctl_el0"));
    mixin(GenSysReg!("cntp_tval_el0"));
    mixin(GenSysReg!("pmccntr_el0"));
    mixin(GenSysReg!("pmccfiltr_el0"));
    mixin(GenSysReg!("pmcntenset_el0"));
    mixin(GenSysReg!("pmcr_el0"));

    mixin(GenSysReg!("daif"));

    // CPUECTLR
    mixin(GenSysReg!("S3_1_C15_C2_1"));
}

enum Sctlr {
    reserved = (3 << 28) | (3 << 22) | (1 << 20) | (1 << 11),
    icache = (1 << 12),
    dcache = (1 << 2),
    mmu = (1 << 0),

    nommu = reserved,
}

enum Mair {
    device_ngnrne = 0b0000_0000,
    normal_cacheable = 0b1111_1111,

    // index depends on how we load mair_el1
    normal_idx = 0,
    device_idx = 1,
}

struct Tcr {
    enum t0sz(uint val) = val;
    enum t1sz(uint val) = val << 16;
    enum ips_36 = 0b010UL << 32;
    enum tg0_4kb = 0b00UL << 14;
    enum tg1_4kb = 0b10UL << 30;
    enum irgn = (0b01 << 8) | (0b01 << 24);
    enum orgn = (0b01 << 10) | (0b01 << 26);
    enum sh = (0b11 << 12) | (0b11 << 28);
}

enum Hcr {
    rw_aarch64 = 1 << 31,
}

enum Scr {
    reserved = 3 << 4,
    rw_aarch64 = 1 << 10,
    ns = 1 << 0,
    hce = 1 << 8, // hvc enable
    smd = 1 << 7, // smc disable
}

enum Mdscr {
    mde = 1 << 15, // monitor debug enable
    ss_bit = 0, // software step
}

enum Mdcr {
    tde = 1 << 8, // trap debug exceptions
}

enum Dbgbcr {
    e = 1,
    aarch64 = 0b1111 << 5,
    el1 = 0b01 << 1,
    el1_el0 = 0b11 << 1,

    unlinked_insn = 0b0000,
    unlinked_mismatch_insn = 0b0100,
}

enum DbgLsc {
    rdonly = 0b01,
    wronly = 0b10,
    rdwr = 0b11,
}

enum Dbgscr {
    mdbgen = 1 << 15,
}

enum Spsr {
    ss_bit = 21,

    d = 1 << 9,
    a = 1 << 8,
    i = 1 << 7,
    f = 1 << 6,

    el2h = 0b1001,
    el1h = 0b0101,
    el0  = 0b0000,
}

enum Exception {
    smc   = 0b010111,
    svc   = 0b010101,
    hvc   = 0b010110,
    brkpt = 0b110000,
    wchpt = 0b110100,
    ss    = 0b110010,

    data_abort_lower = 0b100100,
}
