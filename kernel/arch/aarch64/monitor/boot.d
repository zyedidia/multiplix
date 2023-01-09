module kernel.arch.aarch64.monitor.boot;

import kernel.arch.aarch64.sysreg;

import bits = ulib.bits;

extern (C) void _enter_el1();

void enter_el1() {
    // Set spsr to return to EL1 with SP0.
    SysReg.spsr_el3 = 0b0111_00_0101;
    // Prepare EL1 with MMU and caches disabled.
    SysReg.sctlr_el1 = Sctlr.nommu;
    // Configure EL1 to run in aarch64 mode.
    SysReg.hcr_el2 = Hcr.rw_aarch64;
    // Configure EL2 to run in aarch64 non-secure mode.
    SysReg.scr_el3 = Scr.reserved | Scr.rw_aarch64 | Scr.ns;

    _enter_el1();
}

extern (C) extern void monitorvec();

void init() {
    // Install the trap handler.
    SysReg.vbar_el3 = cast(uintptr) &monitorvec;
}
