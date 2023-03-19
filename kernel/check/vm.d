module kernel.check.vm;

import kernel.arch;
import core.exception;

import ulib.hashmap;

struct VmChecker {
    Hashmap!(uintptr, Pte, hash, eq) shadow_tlb;

    void setup() {
        check(typeof(shadow_tlb).alloc(&shadow_tlb, 1024));
    }

    // Checks that the shadow TLB is consistent with the in-memory pagetable.
    void check_consistency() {
        size_t mappings = 0;
        Pagetable* pt = current_pt();
        import kernel.vm;
        foreach (ref vamap; VmRange(pt)) {
            mappings++;

            bool found = void;
            Pte tlb_pte = shadow_tlb.get(vamap.va, &found);

            if (!found) {
                // not cached in TLB -- insert it
                check(shadow_tlb.put(vamap.va, *vamap.pte));
                continue;
            }

            if (tlb_pte.data != vamap.pte.data) {
                panicf("vm checker: for va %p: %lx is cached in TLB, but stored in the pagetable as %lx\n", cast(void*) vamap.va, tlb_pte.data, vamap.pte.data);
            }
        }

        if (mappings != shadow_tlb.length) {
            panicf("vm checker: count mismatch: TLB mappings (%lx) != Pagetable mappings (%lx)\n", mappings, shadow_tlb.length);
        }
    }

    // Clears all entries from the shadow TLB.
    void on_vmfence() {
        shadow_tlb.clear();
    }
}
