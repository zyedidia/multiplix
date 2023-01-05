module kernel.arch.aarch64.tls;

import kernel.arch.aarch64.sysreg;

void set_tls_base(void* base) {
    version (monitor) {
        SysReg.tpidr_el3 = cast(uintptr) base;
    } else {
        SysReg.tpidr_el1 = cast(uintptr) base;
    }
}
