module kernel.arch.aarch64.tls;

import kernel.cpu;

Cpu* rd_cpu() {
    import kernel.arch.aarch64.sysreg;

    version (monitor) {
        return cast(Cpu*) SysReg.tpidr_el2;
    } else {
        return cast(Cpu*) SysReg.tpidr_el1;
    }
}

void wr_cpu(Cpu* cpu) {
    import kernel.arch.aarch64.sysreg;

    version (monitor) {
        SysReg.tpidr_el2 = cast(uintptr) cpu;
    } else {
        SysReg.tpidr_el1 = cast(uintptr) cpu;
    }
}
