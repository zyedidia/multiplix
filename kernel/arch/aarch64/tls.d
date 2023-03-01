module kernel.arch.aarch64.tls;

int rd_coreid() {
    import kernel.arch.aarch64.sysreg;

    version (monitor) {
        return cast(int) SysReg.tpidr_el2;
    } else {
        return cast(int) SysReg.tpidr_el1;
    }
}

// The thread control block (TCB) is a region of memory sometimes reserved
// before the TLS region for additional thread-local data. On aarch64 it is 16
// bytes. We do not currently make use of the TCB.
enum tcb_size = 16;

void wr_coreid(int coreid) {
    import kernel.arch.aarch64.sysreg;

    version (monitor) {
        SysReg.tpidr_el2 = cast(uintptr) coreid;
    } else {
        SysReg.tpidr_el1 = cast(uintptr) coreid;
    }
}
