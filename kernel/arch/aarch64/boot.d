module kernel.arch.aarch64.boot;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.vm;

import vm = kernel.vm;
import sys = kernel.sys;

shared Pagetable tbl_lo;
shared Pagetable tbl_hi;

void kernel_setup() {
    // device mode
    SysReg.mair_el1 = 0b0000_0000;

    Pagetable* pgtbl_lo = cast(Pagetable*) &tbl_lo;
    pgtbl_lo.map_giga(0, 0, 0);
    pgtbl_lo.map_giga(sys.gb!(1), sys.gb!(1), 0);

    Pagetable* pgtbl_hi = cast(Pagetable*) &tbl_hi;
    pgtbl_hi.map_giga(vm.pa2ka(0), 0, 0);
    pgtbl_hi.map_giga(vm.pa2ka(sys.gb!(1)), sys.gb!(1), 0);

    /* SysReg.tcr_el1 = 0x1B51B351B; */
    SysReg.tcr_el1 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36;

    SysReg.ttbr0_el1 = cast(uintptr) pgtbl_lo | 1;
    SysReg.ttbr1_el1 = cast(uintptr) pgtbl_hi | 1;

    asm {
        "dsb ish";
        "isb";
    }

    /* SysReg.S3_1_C15_C2_1 = SysReg.S3_1_C15_C2_1 | (1 << 6); // enable CPUECTLR.SMPEN */
    SysReg.sctlr_el1 = SysReg.sctlr_el1 | 1; // enable mmu

    asm { "isb"; }
}
