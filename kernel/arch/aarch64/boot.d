module kernel.arch.aarch64.boot;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.vm;

import vm = kernel.vm;
import sys = kernel.sys;

shared Pagetable tbl_lo;
shared Pagetable tbl_hi;

void kernel_setup() {
    SysReg.mair_el1 = (Mair.device_ngnrne << 8) | Mair.normal_cacheable;

    // Map all memory as device (mair 1) for now. Once we can do finer-grained
    // mapping in the kernel (with an allocator), we can enable caching for
    // normal memory regions.
    Pagetable* pgtbl_lo = cast(Pagetable*) &tbl_lo;
    pgtbl_lo.map_giga(0, 0, Ap.krw, 1);
    pgtbl_lo.map_giga(sys.gb!(1), sys.gb!(1), Ap.krw, 1);

    Pagetable* pgtbl_hi = cast(Pagetable*) &tbl_hi;
    pgtbl_hi.map_giga(vm.pa2ka(0), 0, Ap.krw, 1);
    pgtbl_hi.map_giga(vm.pa2ka(sys.gb!(1)), sys.gb!(1), Ap.krw, 1);

    SysReg.tcr_el1 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36 | Tcr.irgn | Tcr.orgn | Tcr.sh;

    SysReg.ttbr0_el1 = cast(uintptr) pgtbl_lo | 1;
    SysReg.ttbr1_el1 = cast(uintptr) pgtbl_hi | 1;

    asm {
        "dsb ish";
        "isb";
    }

    /* SysReg.S3_1_C15_C2_1 = SysReg.S3_1_C15_C2_1 | (1 << 6); // enable CPUECTLR.SMPEN */
    SysReg.sctlr_el1 = SysReg.sctlr_el1 | 1 | (1 << 12) | (1 << 2); // enable mmu and caches

    asm { "isb"; }
}
