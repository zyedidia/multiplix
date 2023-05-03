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
void sev() {
    asm {
        "sev";
    }
}

usize rdcpu() {
    if (ismonitor()) {
        assert(SysReg.currentel >> 2 != 0b01);
        return SysReg.tpidr_el2;
    } else {
        assert(SysReg.currentel >> 2 == 0b01);
        return SysReg.tpidr_el1;
    }
}

void wrcpu(usize cpu) {
    if (ismonitor()) {
        assert(SysReg.currentel >> 2 != 0b01);
        SysReg.tpidr_el2 = cpu;
    } else {
        assert(SysReg.currentel >> 2 == 0b01);
        SysReg.tpidr_el1 = cpu;
    }
}

extern (C) noreturn _halt() {
    while (1) {
        wfe();
    }
}
