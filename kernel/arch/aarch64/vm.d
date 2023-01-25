module kernel.arch.aarch64.vm;

import bits = ulib.bits;
import io = ulib.io;

import sys = kernel.sys;

import ulib.option;
import ulib.memory;

import kernel.vm;
import kernel.alloc;
import kernel.board;

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

    uintptr pa() {
        return addr << 12;
    }

    void pa(uintptr pa) {
        addr = pa >> 12;
    }

    bool leaf(Pte.Pg level) {
        if (level == Pte.Pg.normal) {
            return true;
        }
        return !this.table;
    }

    bool read() {
        return true;
    }

    bool write() {
        return ap == Ap.krw || ap == Ap.urw;
    }

    bool exec() {
        return !pxn;
    }

    bool user() {
        return ap == Ap.urw || ap == Ap.ur;
    }

    enum Pg {
        normal = 0,
        mega = 1,
        giga = 2,

        min = normal,
        max = giga,
    }

    static Pg down(Pg type) {
        assert(type != Pg.min);
        return cast(Pg) (cast(int) type - 1);
    }
}

enum Ap {
    krw = 0b00,
    urw = 0b01,
    kr = 0b10,
    ur = 0b11,
}

enum Perm {
    krwx = Ap.krw,
    urwx = Ap.urw,
}

private uintptr vpn(uint level, uintptr va) {
    return (va >> 12+9*level) & bits.mask!uintptr(9);
}

struct VaMapping {
    uintptr va;
    uintptr pa;
    bool user;
}

struct Pagetable {
    align(4096) Pte[512] ptes;

    // Lookup the pte corresponding to 'va'. Stops after the corresponding
    // level. If 'alloc' is true, allocates new pagetables as necessary.
    Opt!(Pte*) walk(A, bool alloc)(uintptr va, ref Pte.Pg endlevel, A* allocator) {
        Pagetable* pt = &this;

        for (Pte.Pg level = Pte.Pg.max; level > endlevel; level = Pte.down(level)) {
            Pte* pte = &pt.ptes[vpn(level, va)];
            if (pte.valid && !pte.table) {
                endlevel = level;
                return Opt!(Pte*)(pte);
            } else if (pte.valid) {
                pt = cast(Pagetable*) pa2kpa(pte.pa);
            } else {
                static if (!alloc) {
                    endlevel = level;
                    return Opt!(Pte*).none;
                } else {
                    auto pg = kalloc_block(allocator, Pagetable.sizeof);
                    if (!pg.has()) {
                        endlevel = level;
                        return Opt!(Pte*).none;
                    }
                    pt = cast(Pagetable*) pg.get();
                    memset(pt, 0, Pagetable.sizeof);
                    pte.pa = kpa2pa(cast(uintptr) pt);
                    pte.valid = 1;
                    pte.table = 1;
                }
            }
        }
        return Opt!(Pte*)(&pt.ptes[vpn(endlevel, va)]);
    }

    Opt!(Pte*) walk(uintptr va, ref Pte.Pg endlevel) {
        return walk!(void, false)(va, endlevel, null);
    }

    // Map 'va' to 'pa' with the given page size and permissions. Returns false
    // if allocation failed.
    bool map(A)(uintptr va, uintptr pa, Pte.Pg pgtyp, ubyte perm, A* allocator) {
        auto pte_ = walk!(A, true)(va, pgtyp, allocator);
        if (!pte_.has()) {
            return false;
        }
        auto pte = pte_.get();
        pte.pa = pa;
        pte.ap = perm;
        pte.valid = 1;
        if (pgtyp == Pte.Pg.normal) {
            // last level PTEs need this bit enabled (confusing)
            pte.table = 1;
        } else {
            pte.table = 0;
        }
        pte.sh = 0b11;
        pte.af = 1;
        pte.index = System.mem_type(pa);
        return true;
    }

    void map_giga(uintptr va, uintptr pa, ubyte perm) {
        auto idx = bits.get(va, 38, 30);
        ptes[idx].pa = pa;
        ptes[idx].valid = 1;
        ptes[idx].table = 0;
        ptes[idx].ap = perm;
        ptes[idx].af = 1;
        ptes[idx].sh = 0b11;
        ptes[idx].index = System.mem_type(pa);
    }

    Opt!(VaMapping) lookup(uintptr va) {
        Pte.Pg pgtype;
        auto pte_ = walk(va, pgtype);
        if (!pte_.has() || pte_.get().leaf(pgtype)) {
            return Opt!(VaMapping).none;
        }
        auto pte = pte_.get();
        return Opt!(VaMapping)(VaMapping(va, pte.pa, pte.ap == Ap.urw));
    }

    static size_t level2size(Pte.Pg type) {
        final switch (type) {
            case Pte.Pg.normal: return 4096;
            case Pte.Pg.mega: return sys.mb!(2);
            case Pte.Pg.giga: return sys.gb!(1);
        }
    }
}
