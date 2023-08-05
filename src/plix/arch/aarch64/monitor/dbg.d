module plix.arch.aarch64.monitor.dbg;

import plix.arch.aarch64.sysreg : SysReg, Dbgbcr;

void set_watchpoint(uint n, uintptr addr, uint lsc) {
    SysReg.dbgwvr0_el1 = addr;
    SysReg.dbgwcr0_el1 = lsc << 3 | 0b11111111 << 5 | Dbgbcr.el1_el0 | Dbgbcr.e;
}

void clear_watchpoint(uint n) {
    SysReg.dbgwcr0_el1 = 0;
}
