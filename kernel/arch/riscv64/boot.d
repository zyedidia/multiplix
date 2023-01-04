module kernel.arch.riscv64.boot;

import core.sync;

import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.vm;

import kernel.board;

import sys = kernel.sys;

// Early pagetable (only maps gigapages since we don't have an allocator yet).
__gshared Pagetable39 kpagetable;

// Sets up identity-mapped virtual memory and enables interrupts in SIE. After
// running this function it is possible to jump to high kernel addresses.
void kernel_setup(bool primary) {
    if (primary) {
        // Set up an identity-mapped pagetable.
        auto map_region = (System.MemRange range, Pagetable39* pt) {
            for (size_t addr = range.start; addr < range.start + range.sz; addr += sys.gb!(1)) {
                pt.map_giga(addr, addr, Perm.krwx);
                pt.map_giga(sys.highmem_base + addr, addr, Perm.krwx);
            }
        };

        Pagetable39* pgtbl = cast(Pagetable39*) &kpagetable;
        map_region(System.device, pgtbl);
        map_region(System.mem, pgtbl);
    }


    // Enable virtual memory with identity-mapped pagetable.
    Csr.satp = kpagetable.satp(0);
    vm_fence();

    // Prepare to enable interrupts (only will be enabled when sstatus is
    // written as well).
    Csr.sie = Csr.sie | (1UL << Sie.seie) | (1UL << Sie.stie) | (1UL << Sie.ssie);

    // enable SUM bit so supervisor mode can access usermode pages
    // (currently not necessary, so commented out)
    // Csr.sstatus = bits.set(Csr.sstatus, Sstatus.sum);
}
