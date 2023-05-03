module plix.arch.aarch64.monitor.boot;

import plix.arch.aarch64.sysreg : SysReg, Scr, Spsr, Hcr, Sctlr, Mdscr, Mdcr;

import bits = core.bits;

extern (C) void _enter_el1();
extern (C) void _enter_el2();

void enter_el2() {
    // Set spsr to return to EL2h.
    SysReg.spsr_el3 = Spsr.a | Spsr.i | Spsr.f | Spsr.el2h;
    // Configure EL2 to run in aarch64 non-secure mode.
    SysReg.scr_el3 = Scr.reserved | Scr.rw_aarch64 | Scr.ns | Scr.hce | Scr.smd;
    // Configure EL2 with MMU and caches disabled.
    SysReg.sctlr_el2 = Sctlr.nommu;
    // Enable SIMD/FP.
    SysReg.cptr_el3 = bits.clear(SysReg.cptr_el3, 10);
    SysReg.cptr_el2 = bits.clear(SysReg.cptr_el2, 10);

    _enter_el2();
}

void enter_el1() {
    // Set spsr to return to EL1h.
    SysReg.spsr_el2 = Spsr.a | Spsr.i | Spsr.f | Spsr.el1h;
    // Configure EL1 to run in aarch64 mode.
    SysReg.hcr_el2 = Hcr.rw_aarch64;
    // Enable all debug exceptions in kernel mode.
    SysReg.mdscr_el1 = SysReg.mdscr_el1 | Mdscr.mde;
    // Route debug exceptions to EL2.
    SysReg.mdcr_el2 = SysReg.mdcr_el2 | Mdcr.tde;
    // Clear the OS lock.
    SysReg.oslar_el1 = 0;
    // Enable SIMD/FP in kernel.
    SysReg.cpacr_el1 = bits.write(SysReg.cpacr_el1, 21, 20, 0b11);

    _enter_el1();
}

void enter_kmode() {
    enter_el1();
}

extern (C) extern void monitorvec();

void monitor_init() {
    enter_el2();

    // Install the trap handler.
    SysReg.vbar_el2 = cast(uintptr) &monitorvec;
}

// Should only be called after ttbr0_el1 is initialized.
void enable_vm() {
    import plix.arch.aarch64.sysreg : Mair, Tcr, SysReg;
    import plix.arch.aarch64.cache : sysreg_fence;

    SysReg.mair_el2 = (Mair.device_ngnrne << Mair.device_idx * 8) | (Mair.normal_cacheable << Mair.normal_idx * 8);
    SysReg.tcr_el2 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36 | Tcr.irgn | Tcr.orgn | Tcr.sh;
    SysReg.ttbr0_el2 = SysReg.ttbr0_el1;
    sysreg_fence();
    SysReg.sctlr_el2 = SysReg.sctlr_el2 | Sctlr.mmu | Sctlr.icache | Sctlr.dcache; // enable mmu and caches
    sysreg_fence();
}
