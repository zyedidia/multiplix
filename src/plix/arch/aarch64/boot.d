module plix.arch.aarch64.boot;

import plix.arch.aarch64.sysreg : SysReg, Tcr, Sctlr, Mair;
import plix.arch.aarch64.vm : Pagetable, Pte;

import plix.alloc.bump : BumpAlloc;
import plix.vm : pa2hka, Perm;
import plix.board : Machine;

import sys = plix.sys;

__gshared Pagetable tbl;
__gshared Pagetable[4] l2pts;
__gshared usize pt;

Pagetable* ptalloc() {
    if (pt >= l2pts.length) {
        return null;
    }
    Pagetable* pt = &l2pts[pt++];
    return pt;
}

// Map the kernel into the high region of the address space. Called during initialization.
void kernel_procmap(Pagetable* pt) {
    // don't have to do anything here because ttbr1_el1 already contains the kernel pagetable
}

void kernel_setup(bool primary) {
    // Load normal into index 0 and device into index 1.
    SysReg.mair_el1 = (Mair.device_ngnrne << Mair.device_idx * 8) | (Mair.normal_cacheable << Mair.normal_idx * 8);

    if (primary) {
        void map_region(Machine.MemRange range, Pagetable* pt) {
            for (usize addr = range.start; addr < range.start + range.sz; addr += sys.mb!(2)) {
                ensure(pt.map(addr, addr, Pte.Pg.mega, Perm.r | Perm.w | Perm.x, &ptalloc));
                ensure(pt.map(pa2hka(addr), addr, Pte.Pg.mega, Perm.r | Perm.w | Perm.x, &ptalloc));
            }
        }

        foreach (r; Machine.mem_ranges) {
            map_region(r, &tbl);
        }
    }

    SysReg.tcr_el1 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36 | Tcr.irgn | Tcr.orgn | Tcr.sh;

    SysReg.ttbr0_el1 = cast(uintptr) &tbl;
    SysReg.ttbr1_el1 = cast(uintptr) &tbl;

    asm {
        "dsb sy";
        "isb";
    }

    SysReg.sctlr_el1 = SysReg.sctlr_el1 | Sctlr.mmu | Sctlr.icache | Sctlr.dcache; // enable mmu and caches

    asm {
        "dsb sy";
        "isb";
    }
}
