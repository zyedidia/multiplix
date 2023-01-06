module kernel.arch.aarch64.tls;

import kernel.arch.aarch64.sysreg;

void set_tls_base(void* base) {
    // TODO: why does LLVM always add 16 to tpidr_elx to access the TLS base?
    version (monitor) {
        SysReg.tpidr_el3 = cast(uintptr) base - 16;
    } else {
        SysReg.tpidr_el1 = cast(uintptr) base - 16;
    }
}
