module plix.arch.riscv64.boot;

import plix.arch.riscv64.cache : vm_fence;
import plix.arch.riscv64.csr : Csr, Sstatus, Sie;
import plix.arch.riscv64.vm : Pagetable;
import plix.board : Machine;
import plix.vm : pa2hka, Perm;

import sys = plix.sys;

// Early pagetable (only maps gigapages since we don't have an allocator yet).
__gshared Pagetable pagetable;

// Maps the kernel into the high region of the virtual address space.
void kernel_procmap(Pagetable* pt) {
    foreach (range; Machine.mem_ranges) {
        for (usize addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
            pt.map_giga(pa2hka(addr), addr, Perm.r | Perm.w | Perm.x);
        }
    }
}

// Sets up identity-mapped virtual memory and enables interrupts in SIE. After
// running this function it is possible to jump to high kernel addresses. The
// parameter `primary` controls whether this function initializes a new
// pagetable or uses an existing one.
void kernel_setup(bool primary) {
    if (primary) {
        // Set up an identity-mapped pagetable.
        void map_region (Machine.MemRange range, Pagetable* pt) {
            for (usize addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
                pt.map_giga(addr, addr, Perm.rwx);
                pt.map_giga(pa2hka(addr), addr, Perm.rwx);
            }
        }

        Pagetable* pgtbl = &pagetable;

        foreach (r; Machine.mem_ranges) {
            map_region(r, pgtbl);
        }
    }


    // Enable virtual memory with identity-mapped pagetable.
    Csr.satp = pagetable.satp(0);
    vm_fence();

    // Prepare to enable interrupts (only will be enabled when sstatus is
    // written as well).
    Csr.sie = (1UL << Sie.stie) | (1UL << Sie.ssie);

    // enable SUM bit so supervisor mode can access usermode pages
    Csr.sstatus = Csr.sstatus | (1UL << Sstatus.sum);
}

extern (C) extern void kernelvec();

void kernel_init() {
    Csr.stvec = cast(uintptr) &kernelvec;
}
