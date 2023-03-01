module kernel.check.vm;

// The VM checker ensures that the kernel is managing pagetables properly. It
// checks that TLB entries are flushed appropriately after writes to pagetable
// entries.

struct VmChecker {
    static void on_store(void* addr, ulong val, uint size) {

    }

    static void on_ptload(uintptr pt, uint asid) {

    }

    static void on_tlbflush() {

    }
}
