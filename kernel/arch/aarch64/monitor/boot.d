module kernel.arch.aarch64.monitor.boot;

import kernel.arch.aarch64.sysreg;

import bits = ulib.bits;

extern (C) extern __gshared ubyte _el1_entrypoint;

void enter_el1() {
    pragma(LDC_never_inline);
    // We want 'eret' to jump to _el1_entrypoint, so we write it to elr_el3.
    // TODO: not sure why this doesn't work, have to use inline asm for this instead
    /* SysReg.elr_el3 = cast(uintptr) &_el1_entrypoint; */

    // Set spsr to return to EL1 with SP0.
    SysReg.spsr_el3 = 0b0111_00_0101;
    // Prepare EL1 with MMU and caches disabled.
    SysReg.sctlr_el1 = Sctlr.nommu;
    // Configure EL1 to run in aarch64 mode.
    SysReg.hcr_el2 = Hcr.rw_aarch64;
    // Configure EL2 to run in aarch64 non-secure mode.
    SysReg.scr_el3 = Scr.reserved | Scr.rw_aarch64 | Scr.ns;

    asm {
        // perform the switch and jump to _el1_entrypoint
        "mov x0, sp" : : : "x0";
        "msr sp_el1, x0";
        "ldr x0, =_el1_entrypoint" : : : "x0";
        "msr elr_el3, x0";
        "eret";
        "_el1_entrypoint:";
    }
}
