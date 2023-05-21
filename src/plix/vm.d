module plix.vm;

import sys = plix.sys;

// Returns true if va is a kernel address.
pragma(inline, true)
bool iska(uintptr va) {
    return va >= sys.highmem_base;
}

// Converts kernel address to physical address.
pragma(inline, true)
uintptr ka2pa(uintptr ka) {
    return ka - sys.highmem_base;
}

// Converts a physical address to a high kernel address.
pragma(inline, true)
uintptr pa2hka(uintptr pa) {
    return pa + sys.highmem_base;
}

// Converts a kernel address to a physical address if the kernel address is
// higher than sys.highmem_base (a valid kernel address), otherwise returns the
// address as-is (i.e., this converts kernel and physical addresses to physical
// addresses).
pragma(inline, true)
uintptr kpa2pa(uintptr kpa) {
    if (kpa >= sys.highmem_base) {
        return ka2pa(kpa);
    }
    return kpa;
}

// Converts a physical address to a kernel address if in the kernel, or a
// physical address if in the monitor (where kernel addresses don't exist).
pragma(inline, true)
uintptr pa2ka(uintptr pa) {
    import config : ismonitor;
    if (ismonitor()) {
        return pa;
    } else {
        return pa2hka(pa);
    }
}

// Virtual memory permissions.
enum Perm {
    r = 1 << 0,   // read
    w = 1 << 1,   // write
    x = 1 << 2,   // execute
    u = 1 << 3,   // user-accessible
    cow = 1 << 4, // copy-on-write

    rw  = r | w,
    rwx = rw | x,
    urx = u | r | x,
    urw  = u | rw,
    urwx = urw | x,
}

import plix.arch.vm : Pagetable, PtLevel;

bool mappg(Pagetable* pt, usize va, ubyte* page, Perm perm) {
    return pt.map(va, ka2pa(cast(uintptr) page), PtLevel.normal, perm);
}

import plix.arch.vm : Pagetable, Pte, PtLevel;
import plix.proc : Proc;
import core.option : Option;

struct VaMapping {
    Pte* pte;
    uintptr va_;

    uintptr va() { return va_; }
    uintptr pa() { return pte.pa; }
    Perm perm()  { return pte.perm; }
    bool read()  { return (pte.perm & Perm.r) != 0; }
    bool write() { return (pte.perm & Perm.w) != 0; }
    bool exec()  { return (pte.perm & Perm.x) != 0; }
    bool user()  { return (pte.perm & Perm.u) != 0; }
    bool cow()   { return (pte.perm & Perm.cow) != 0; }

    ubyte[] pg() {
        return (cast(ubyte*) pa2ka(pte.pa))[0 .. sys.pagesize];
    }

    ubyte* pg_raw() {
        return cast(ubyte*) pa2ka(pte.pa);
    }
}

// Look up virtual address va in the pagetable.
Option!(VaMapping) lookup(Pagetable* pt, uintptr va) {
    PtLevel lvl = PtLevel.normal;
    Pte* pte = pt.walk(va, lvl);
    if (!pte || !pte.leaf(lvl)) {
        return Option!(VaMapping).none;
    }
    return Option!(VaMapping)(VaMapping(pte, va));
}

struct PtIter {
    usize idx;
    uintptr va;
    Pte* pte;
    Pagetable* pt;

    static PtIter get(Pagetable* pt) {
        return PtIter(0, 0, null, pt);
    }

    bool advance() {
        if (va >= Proc.MAX_VA) {
            return false;
        }

        PtLevel lvl = PtLevel.normal;
        Pte* entry = pt.walk(va, lvl);
        if (entry) {
            if (lvl != PtLevel.normal || !entry.valid()) {
                pte = null;
            } else {
                pte = entry;
            }
            va += Pagetable.level2size(lvl);
        } else {
            pte = null;
            va += Pagetable.level2size(PtLevel.normal);
        }
        return true;
    }

    Option!(VaMapping) next() {
        uintptr va = this.va;
        if (!advance()) {
            return Option!(VaMapping).none;
        }

        while (!pte) {
            va = this.va;
            if (!advance()) {
                return Option!(VaMapping).none;
            }
        }
        return Option!(VaMapping)(VaMapping(pte, va));
    }

    int opApply(scope int delegate(ref VaMapping) dg) {
        for (auto map = next(); map.has(); map = next()) {
            VaMapping m = map.get();
            int r = dg(m);
            if (r) return r;
        }
        return 0;
    }
}
