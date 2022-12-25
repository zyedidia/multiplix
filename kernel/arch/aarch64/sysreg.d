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
    mixin(GenSysReg!("currentel"));

    mixin(GenSysReg!("elr_el3"));
    mixin(GenSysReg!("spsr_el3"));
    mixin(GenSysReg!("scr_el3"));

    mixin(GenSysReg!("hcr_el2"));

    mixin(GenSysReg!("sctlr_el1"));
    mixin(GenSysReg!("sp_el1"));
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

enum Hcr {
    rw_aarch64 = (1 << 31),
}

enum Scr {
    reserved = (3 << 4),
    rw_aarch64 = (1 << 10),
    ns = (1 << 0),
}
