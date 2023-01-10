module kernel.arch.aarch64.boot;

import core.sync;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.vm;

import kernel.board;

import vm = kernel.vm;
import sys = kernel.sys;

shared Pagetable tbl_lo;
shared Pagetable tbl_hi;

void kernel_setup(bool primary) {
    // Load normal into index 0 and device into index 1.
    SysReg.mair_el1 = (Mair.device_ngnrne << 8) | Mair.normal_cacheable;

    if (primary) {
        void map_region(System.MemRange range, Pagetable* pt) {
            for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
                pt.map_giga(addr, addr, Ap.krw, range.type);
                pt.map_giga(vm.pa2ka(addr), addr, Ap.krw, range.type);
            }
        }

        Pagetable* pgtbl_lo = cast(Pagetable*) &tbl_lo;
        map_region(System.early, pgtbl_lo);

        Pagetable* pgtbl_hi = cast(Pagetable*) &tbl_hi;
        map_region(System.early, pgtbl_hi);
    }

    SysReg.tcr_el1 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36 | Tcr.irgn | Tcr.orgn | Tcr.sh;

    SysReg.ttbr0_el1 = cast(uintptr) &tbl_lo | 1;
    SysReg.ttbr1_el1 = cast(uintptr) &tbl_hi | 1;

    asm {
        "dsb ish";
        "isb";
    }

    SysReg.sctlr_el1 = SysReg.sctlr_el1 | 1 | (1 << 12) | (1 << 2); // enable mmu and caches

    asm { "isb"; }
}

shared Pagetable ktbl_hi;

void kernel_setup_alloc(A)(bool primary, A* allocator) {
    pragma(LDC_never_inline);
    if (primary) {
        void map_region (System.MemRange range, Pagetable* pt) {
            for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.mb!(2)) {
                assert(pt.map(addr, addr, Pte.Pg.mega, Ap.krw, range.type, allocator));
                assert(pt.map(vm.pa2ka(addr), addr, Pte.Pg.mega, Ap.krw, range.type, allocator));
            }
        }

        foreach (r; System.mem_ranges) {
            map_region(r, cast(Pagetable*) &ktbl_hi);
        }
    }

    SysReg.ttbr1_el1 = vm.ka2pa(cast(uintptr) &ktbl_hi | 1);

    vm_fence();
    insn_fence();
}
