module kernel.arch.aarch64.monitor.boot;

import kernel.arch.aarch64.sysreg;

import bits = ulib.bits;

extern (C) void _enter_el1();
extern (C) void _enter_el2();

void enter_el2() {
    // Set spsr to return to EL2h.
    SysReg.spsr_el3 = 0b1111_00_1001;
    // Configure EL2 to run in aarch64 non-secure mode.
    SysReg.scr_el3 = Scr.reserved | Scr.rw_aarch64 | Scr.ns | Scr.hce | Scr.smd;
    // Configure EL2 with MMU and caches disabled.
    SysReg.sctlr_el2 = Sctlr.nommu;

    _enter_el2();
}

void enter_el1() {
    // Set spsr to return to EL1h.
    SysReg.spsr_el2 = 0b1111_00_0101;
    // Prepare EL1 with MMU and caches disabled.
    SysReg.sctlr_el1 = Sctlr.nommu;
    // Configure EL1 to run in aarch64 mode.
    SysReg.hcr_el2 = Hcr.rw_aarch64;

    _enter_el1();
}

extern (C) extern void monitorvec();

void init() {
    enter_el2();

    // Install the trap handler.
    SysReg.vbar_el2 = cast(uintptr) &monitorvec;
}
