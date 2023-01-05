module kernel.arch.aarch64.sysreg;

// dfmt off
template GenSysReg(string name) {
    const char[] GenSysReg = `@property static uintptr ` ~ name ~ `() {
        uintptr val;
        asm {
            "mrs %0, ` ~ name ~ `" : "=r"(val);
        }
        return val;
    }
    @property static void ` ~ name ~ `(uintptr v) {
        asm {
            "msr ` ~ name ~ `, %0" : : "r"(v);
        }
    }`;
}
// dfmt on

struct SysReg {
    @property static uintptr currentel() {
        uintptr val;
        asm {
            "mrs %0, currentel" : "=r"(val);
        }
        return val;
    }
    @property static uintptr mpidr_el1() {
        uintptr val;
        asm {
            "mrs %0, mpidr_el1" : "=r"(val);
        }
        return val;
    }
    /* mixin(GenSysReg!("currentel")); */

    mixin(GenSysReg!("elr_el3"));
    mixin(GenSysReg!("spsr_el3"));
    mixin(GenSysReg!("scr_el3"));
    mixin(GenSysReg!("vbar_el3"));
    mixin(GenSysReg!("esr_el3"));
    mixin(GenSysReg!("tpidr_el3"));

    mixin(GenSysReg!("spsr_el2"));
    mixin(GenSysReg!("hcr_el2"));
    mixin(GenSysReg!("tpidr_el2"));

    mixin(GenSysReg!("sctlr_el1"));
    mixin(GenSysReg!("sp_el1"));
    mixin(GenSysReg!("ttbr0_el1"));
    mixin(GenSysReg!("ttbr1_el1"));
    mixin(GenSysReg!("tcr_el1"));
    mixin(GenSysReg!("mair_el1"));
    mixin(GenSysReg!("id_aa64mmfr0_el1"));
    mixin(GenSysReg!("tpidr_el1"));

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
    // Memory: normal outer write-through non-transient read-allocate
    // write-allocate, inner write-through non-transiant read-allocate
    // write-allocate.
    normal_cacheable = 0b1011_1011,
}

struct Tcr {
    enum t0sz(uint val) = val;
    enum t1sz(uint val) = val << 16;
    enum ips_36 = 0b010UL << 32;
    enum tg0_4kb = 0b00UL << 14;
    enum tg1_4kb = 0b10UL << 30;
    enum irgn = (0b10 << 8) | (0b10 << 24);
    enum orgn = (0b10 << 10) | (0b10 << 26);
    enum sh = (0b11 << 12) | (0b11 << 28);
}

enum Hcr {
    rw_aarch64 = (1 << 31),
}

enum Scr {
    reserved = (3 << 4),
    rw_aarch64 = (1 << 10),
    ns = (1 << 0),
}

enum Exception {
    smc = 0b010111,
}
