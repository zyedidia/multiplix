module kernel.arch.aarch64.vm;

import bits = ulib.bits;

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

struct Pagetable {
    align(4096) Pte[512] ptes;

    void map_giga(uintptr va, uintptr pa, uint perm) {
        auto idx = bits.get(va, 38, 30);
        ptes[idx].addr = pa >> 12;
        ptes[idx].valid = 1;
        ptes[idx].table = 0;
        ptes[idx].ap = 0b00;
        ptes[idx].af = 1;
        ptes[idx].sh = 0b11;
        ptes[idx].index = 0;
    }
}
