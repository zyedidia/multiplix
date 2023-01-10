module kernel.arch.aarch64.vm;

import bits = ulib.bits;
import io = ulib.io;

import ulib.option;
import ulib.memory;

import kernel.vm;
import kernel.alloc;

// AArch64 MMU configuration with 39-bit virtual addresses and a granule of 4KB.

struct Pte {
    ulong data;
    // dfmt off
    mixin(bits.field!(data,
        "valid", 1,
        "table", 1, // if this entry is a table entry or leaf entry
        "index", 3, // mair index
        "ns", 1, // non-secure
        "ap", 2, // access permission
        "sh", 2, // shareable
        "af", 1, // access fault
        "_r", 1, // reserved
        "addr", 36,
        "_r2", 5,
        "pxn", 1, // privileged execute never
        "uxn", 1, // unprivileged execute never
        "sw", 4, // reserved for software use
        "_r3", 5,
    ));
    // dfmt on

    enum Pg {
        normal = 0,
        mega = 1,
        giga = 2,
    }
}

enum Ap {
    krw = 0b00,
}

private uintptr vpn(uint level, uintptr va) {
    return (va >> 12+9*level) & bits.mask!uintptr(9);
}

struct Pagetable {
    align(4096) Pte[512] ptes;

    // Lookup the pte corresponding to 'va'. Stops after the corresponding
    // level. If 'alloc' is true, allocates new pagetables as necessary.
    Opt!(Pte*) walk(A)(uintptr va, Pte.Pg endlevel, bool alloc, A* allocator) {
        Pagetable* pt = &this;

        for (int level = 2; level > endlevel; level--) {
            Pte* pte = &pt.ptes[vpn(level, va)];
            if (pte.valid && !pte.table) {
                return Opt!(Pte*)(pte);
            } else if (pte.valid) {
                pt = cast(Pagetable*) pa2kpa(pte.addr << 12);
            } else {
                if (!alloc) {
                    return Opt!(Pte*)(null);
                }
                auto pg = kalloc(allocator, Pagetable.sizeof);
                if (!pg.has()) {
                    return Opt!(Pte*)(null);
                }
                pt = cast(Pagetable*) pg.get();
                memset(pt, 0, Pagetable.sizeof);
                pte.addr = kpa2pa(cast(uintptr) pt) >> 12;
                pte.valid = 1;
                pte.table = 1;
            }
        }
        return Opt!(Pte*)(&pt.ptes[vpn(endlevel, va)]);
    }

    // Map 'va' to 'pa' with the given page size and permissions. Returns false
    // if allocation failed.
    bool map(A)(uintptr va, uintptr pa, Pte.Pg pgtyp, ubyte perm, ubyte mair, A* allocator) {
        auto opte = walk(va, pgtyp, true, allocator);
        if (!opte.has()) {
            return false;
        }
        auto pte = opte.get();
        pte.addr = pa >> 12;
        pte.ap = perm;
        pte.valid = 1;
        pte.table = 0;
        pte.sh = 0b11;
        pte.af = 1;
        pte.index = mair;
        return true;
    }

    void map_giga(uintptr va, uintptr pa, ubyte perm, ubyte mair) {
        auto idx = bits.get(va, 38, 30);
        ptes[idx].addr = pa >> 12;
        ptes[idx].valid = 1;
        ptes[idx].table = 0;
        ptes[idx].ap = perm;
        ptes[idx].af = 1;
        ptes[idx].sh = 0b11;
        ptes[idx].index = mair;
    }
}
