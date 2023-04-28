module plix.arch.aarch64.cpu;

import plix.arch.aarch64.sysreg : SysReg;

// TODO: write to tpidr_el1 in non-monitor mode.
pragma(inline, true)
usize rdcpu() {
    return SysReg.tpidr_el2;
}

void wrcpu(usize cpu) {
    SysReg.tpidr_el2 = cpu;
}
