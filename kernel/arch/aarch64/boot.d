module kernel.arch.aarch64.boot;

import core.sync;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.vm;

import fwi = kernel.arch.aarch64.fwi;

import kernel.board;
import kernel.alloc;

import vm = kernel.vm;
import sys = kernel.sys;

shared Pagetable tbl;

align(4096) __gshared ubyte[4096 * 4] ptheap;

bool kernel_map(Pagetable* pt) {
    // don't have to do anything here because ttbr1_el1 already contains the kernel pagetable
    return true;
}

void kernel_setup(bool primary) {
    // Load normal into index 0 and device into index 1.
    SysReg.mair_el1 = (Mair.device_ngnrne << Mair.device_idx * 8) | (Mair.normal_cacheable << Mair.normal_idx * 8);

    if (primary) {
        auto pgalloc = BumpAllocator!(4096)(&ptheap[0], ptheap.length);
        void map_region (System.MemRange range, Pagetable* pt) {
            for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.mb!(2)) {
                assert(pt.map(addr, addr, Pte.Pg.mega, Ap.krw, &pgalloc));
                assert(pt.map(vm.pa2ka(addr), addr, Pte.Pg.mega, Ap.krw, &pgalloc));
            }
        }

        foreach (r; System.mem_ranges) {
            map_region(r, cast(Pagetable*) &tbl);
        }
    }

    SysReg.tcr_el1 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36 | Tcr.irgn | Tcr.orgn | Tcr.sh;

    SysReg.ttbr0_el1 = cast(uintptr) &tbl;
    SysReg.ttbr1_el1 = cast(uintptr) &tbl;

    asm {
        "dsb sy";
        "isb";
    }

    SysReg.sctlr_el1 = SysReg.sctlr_el1 | 1 | (1 << 2) | (1 << 12); // enable mmu and caches

    asm {
        "dsb sy";
        "isb";
    }
}
