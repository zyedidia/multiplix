module kernel.arch.aarch64.boot;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.vm;

import kernel.board;

import vm = kernel.vm;
import sys = kernel.sys;

shared Pagetable tbl_lo;
shared Pagetable tbl_hi;

void kernel_setup(bool primary) {
    SysReg.mair_el1 = (Mair.device_ngnrne << 8) | Mair.normal_cacheable;

    if (primary) {
        auto map_region = (System.MemRange range, Pagetable* pt) {
            for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
                // Map all memory as device (mair 1) for now. Once we can do finer-grained
                // mapping in the kernel (with an allocator), we can enable caching for
                // normal memory regions.
                pt.map_giga(addr, addr, Ap.krw, 1);
                pt.map_giga(sys.highmem_base + addr, addr, Ap.krw, 1);
            }
        };

        Pagetable* pgtbl_lo = cast(Pagetable*) &tbl_lo;
        map_region(System.device, pgtbl_lo);
        map_region(System.mem, pgtbl_lo);

        Pagetable* pgtbl_hi = cast(Pagetable*) &tbl_hi;
        map_region(System.device, pgtbl_hi);
        map_region(System.mem, pgtbl_hi);
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
