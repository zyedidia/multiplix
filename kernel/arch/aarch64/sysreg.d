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
}
