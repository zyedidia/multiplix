module plix.arch.aarch64.cpu;

import plix.arch.aarch64.sysreg : SysReg;
import config : ismonitor;

pragma(inline, true)
void wfe() {
    asm {
        "wfe";
    }
}

pragma(inline, true)
usize rdcpu() {
    if (ismonitor()) {
        return SysReg.tpidr_el2;
    } else {
        return SysReg.tpidr_el1;
    }
}

void wrcpu(usize cpu) {
    if (ismonitor()) {
        SysReg.tpidr_el2 = cpu;
    } else {
        SysReg.tpidr_el1 = cpu;
    }
}

extern (C) noreturn _halt() {
    while (1) {
        wfe();
    }
}
