module plix.arch.aarch64.vm;

import bits = core.bits;
import sys = plix.sys;

import plix.alloc : knew;
import plix.vm : pa2ka, Perm, kpa2pa;
import plix.board : Machine;
import plix.arch.aarch64.sysreg : SysReg;

// AArch64 MMU configuration with 39-bit virtual addresses and a granule of 4KB.

enum PtPerm {
    r,
    w,
    x,
    u,
}

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
        "_r2", 4,
        "dbm", 1,
        "contiguous", 1,
        "pxn", 1, // privileged execute never
        "uxn", 1, // unprivileged execute never
        "cow", 1, // copy-on-write (software use)
        "sw", 3, // reserved for software use
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

    void perm(Perm perm) {
        valid = (perm & Perm.r) != 0;
        cow = (perm & Perm.cow) != 0;
        pxn = (perm & Perm.x) == 0;
        uxn = (perm & Perm.x) == 0 || (perm & Perm.u) == 0;
        ubyte ap = 0;
        if ((perm & Perm.u) != 0)
            ap |= 0b01; // user-accessible
        if ((perm & Perm.w) == 0)
            ap |= 0b10; // read-only
        this.ap = ap;
    }

    Perm perm() {
        Perm p;
        if (valid)
            p |= Perm.r;
        if (!uxn || !pxn)
            p |= Perm.x;
        // user-accessible if user could execute or read/write
        if (!uxn || (ap & 0b01) != 0)
            p |= Perm.u;
        if ((ap & 0b10) == 0)
            p |= Perm.w;
        if (cow)
            p |= Perm.cow;
        return p;
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

private uintptr vpn(uint level, uintptr va) {
    return (va >> 12+9*level) & bits.mask!uintptr(9);
}

struct Pagetable {
    align(4096) Pte[512] ptes;

    // Lookup the pte corresponding to 'va'. Stops after the corresponding
    // level. If 'alloc' is true, allocates new pagetables as necessary.
    Pte* walk(uintptr va, ref Pte.Pg endlevel, Pagetable* function() ptalloc) {
        Pagetable* pt = &this;

        for (Pte.Pg level = Pte.Pg.max; level > endlevel; level = Pte.down(level)) {
            Pte* pte = &pt.ptes[vpn(level, va)];
            if (pte.valid && !pte.table) {
                endlevel = level;
                return pte;
            } else if (pte.valid) {
                pt = cast(Pagetable*) pa2ka(pte.pa);
            } else {
                if (!ptalloc) {
                    endlevel = level;
                    return null;
                } else {
                    pt = ptalloc();
                    if (!pt) {
                        endlevel = level;
                        return null;
                    }
                    pte.pa = kpa2pa(cast(uintptr) pt);
                    pte.valid = 1;
                    pte.table = 1;
                }
            }
        }
        return &pt.ptes[vpn(endlevel, va)];
    }

    Pte* walk(uintptr va, ref Pte.Pg endlevel) {
        return walk(va, endlevel, &knew!(Pagetable));
    }

    // Recursively free all pagetable pages.
    void free(Pte.Pg level = Pte.Pg.max) {
    }

    bool map(uintptr va, uintptr pa, Pte.Pg pgtyp, Perm perm) {
        return map(va, pa, pgtyp, perm, &knew!(Pagetable));
    }

    // Map 'va' to 'pa' with the given page size and permissions. Returns false
    // if allocation failed.
    bool map(uintptr va, uintptr pa, Pte.Pg pgtyp, Perm perm, Pagetable* function() ptalloc) {
        Pte* pte = walk(va, pgtyp, ptalloc);
        if (!pte) {
            return false;
        }
        pte.pa = pa;
        pte.perm = perm;
        pte.valid = 1;
        if (pgtyp == Pte.Pg.normal) {
            // last level PTEs need this bit enabled (confusing)
            pte.table = 1;
        } else {
            pte.table = 0;
        }
        pte.sh = 0b11;
        pte.af = 1;

        pte.index = Machine.mem_type(pa);
        return true;
    }

    void map_giga(uintptr va, uintptr pa, Perm perm) {
        auto idx = bits.get(va, 38, 30);
        ptes[idx].pa = pa;
        ptes[idx].valid = 1;
        ptes[idx].table = 0;
        ptes[idx].perm = perm;
        ptes[idx].af = 1;
        ptes[idx].sh = 0b11;

        ptes[idx].index = Machine.mem_type(pa);
    }

    static usize level2size(Pte.Pg type) {
        final switch (type) {
            case Pte.Pg.normal: return 4096;
            case Pte.Pg.mega: return sys.mb!(2);
            case Pte.Pg.giga: return sys.gb!(1);
        }
    }
}

Pagetable* current_pt() {
    return cast(Pagetable*) pa2ka((SysReg.ttbr0_el1) & 0xfffffffffffe);
}

void kernel_ptswitch(Pagetable* pt) {
    // don't need to do anything on aarch64 because TTBR1_EL1 is separate from
    // TTBR0_EL1
}
