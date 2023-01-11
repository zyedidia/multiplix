module kernel.arch.aarch64.tls;

import kernel.arch.aarch64.sysreg;

// The thread control block (TCB) is a region of memory sometimes reserved
// before the TLS region for additional thread-local data. On aarch64 it is 16
// bytes. We do not currently make use of the TCB.
enum tcb_size = 16;

void set_tls_base(void* base) {
    version (monitor) {
        SysReg.tpidr_el3 = cast(uintptr) base;
    } else {
        SysReg.tpidr_el1 = cast(uintptr) base;
    }
    asm { "" ::: "memory"; }
}
