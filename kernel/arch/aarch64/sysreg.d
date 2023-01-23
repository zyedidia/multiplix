module kernel.arch.aarch64.sysreg;

// dfmt off
const char[] GenSysReg(string name) = GenSysRegRdOnly!(name) ~ GenSysRegWrOnly!(name);
const char[] GenSysRegRdOnly(string name) =
`static uintptr ` ~ name ~ `() {
    uintptr val;
    asm {
        "mrs %0, ` ~ name ~ `" : "=r"(val);
    }
    return val;
}`;
const char[] GenSysRegWrOnly(string name) =
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

    mixin(GenSysReg!("dbgbcr0_el1"));
    mixin(GenSysReg!("dbgbvr0_el1"));

    mixin(GenSysReg!("cntfrq_el0"));
    mixin(GenSysRegRdOnly!("cntpct_el0"));
    mixin(GenSysReg!("cntp_ctl_el0"));
    mixin(GenSysReg!("cntp_tval_el0"));

    mixin(GenSysReg!("daif"));

    // a clunkier but more flexible interface for debug registers
    /* struct dbgbcr_el1(uint n) { */
    /*     static void wr(uintptr v) { */
    /*         import ulib.meta; */
    /*         mixin(`asm { */
    /*             "msr dbgbcr` ~ itoa!uint(n) ~ `_el1, %0" :: "r"(v); */
    /*         }`); */
    /*     } */
    /* } */

    // CPUECTLR
    mixin(GenSysReg!("S3_1_C15_C2_1"));
}

enum Sctlr {
    reserved = (3 << 28) | (3 << 22) | (1 << 20) | (1 << 11),
    ee_little_endian = (0 << 25),
    eoe_little_endian = (0 << 24),
    icache_disabled = (0 << 12),
    dcache_disabled = (0 << 2),
    mmu_disabled = (0 << 0),
    mmu_enabled = (1 << 0),

    nommu = reserved | ee_little_endian | icache_disabled | dcache_disabled | mmu_disabled,
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
    ss = 0, // software step
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

enum Dbgscr {
    mdbgen = 1 << 15,
}

enum Spsr {
    ss = 21,
}

enum Exception {
    smc = 0b010111,
    svc = 0b010101,
    hvc = 0b010110,
    brkpt = 0b110000,
    ss = 0b110010,
}
