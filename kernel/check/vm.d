module kernel.check.vm;

import kernel.arch;
import core.exception;

import ulib.hashmap;

struct VmChecker {
    Hashmap!(uintptr, Pte, hash, eq) shadow_tlb;

    private Pagetable* get_pt() {
        import kernel.arch.riscv64.csr;
        return cast(Pagetable*) ((Csr.satp & 0xfffffffffffUL) << 12);
    }

    void setup() {
        check(typeof(shadow_tlb).alloc(&shadow_tlb, 1024));
    }

    void on_translate(uintptr va) {
        Pagetable* pt = get_pt();

        auto lvl = Pte.Pg.normal;
        Pte* pte = pt.walk(va, lvl);

        bool found = void;
        Pte tlb_pte = shadow_tlb.get(va, &found);

        if (!pte) {
            if (!found)
                return; // OK
            panicf("vm checker: PTE for va %p is no longer valid, but still cached\n", cast(void*) va);
        }

        if (!found) {
            // Shadow TLB doesn't have an entry for this PTE, so insert it.
            check(shadow_tlb.put(va, *pte));
            return;
        }

        if (tlb_pte.data != pte.data) {
            // PTEs don't match -- error.
            panicf("vm checker: attempt to use unflushed PTE for va %p: %lx != %lx\n", cast(void*) va, tlb_pte.data, pte.data);
        }
    }

    void on_vmfence() {
        shadow_tlb.clear();
    }
}
