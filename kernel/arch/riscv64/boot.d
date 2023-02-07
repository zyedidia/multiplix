module kernel.arch.riscv64.boot;

import core.sync;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.vm;

import kernel.board;

import sys = kernel.sys;
import vm = kernel.vm;

// Early pagetable (only maps gigapages since we don't have an allocator yet).
__gshared Pagetable kpagetable;

bool kernel_map(Pagetable* pt) {
    // Map kernel into the high part of the address space
    foreach (range; Machine.mem_ranges) {
        for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
            pt.map_giga(vm.pa2ka(addr), addr, Perm.krwx);
        }
    }
    return true;
}

// Sets up identity-mapped virtual memory and enables interrupts in SIE. After
// running this function it is possible to jump to high kernel addresses.
void kernel_setup(bool primary) {
    if (primary) {
        // Set up an identity-mapped pagetable.
        void map_region (Machine.MemRange range, Pagetable* pt) {
            for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
                pt.map_giga(addr, addr, Perm.krwx);
                pt.map_giga(vm.pa2ka(addr), addr, Perm.krwx);
            }
        }

        Pagetable* pgtbl = &kpagetable;

        foreach (r; Machine.mem_ranges) {
            map_region(r, pgtbl);
        }
    }


    // Enable virtual memory with identity-mapped pagetable.
    Csr.satp = kpagetable.satp(0);
    vm_fence();

    // Prepare to enable interrupts (only will be enabled when sstatus is
    // written as well).
    Csr.sie = (1UL << Sie.stie) | (1UL << Sie.ssie);

    // enable SUM bit so supervisor mode can access usermode pages
    // (currently not necessary, so commented out)
    // Csr.sstatus = bits.set(Csr.sstatus, Sstatus.sum);
}
