module kernel.vm;

import sys = kernel.sys;

// Returns true if va is a kernel address.
bool iska(uintptr va) {
    return va >= sys.highmem_base;
}

// Converts kernel address to physical address.
uintptr ka2pa(uintptr ka) {
    return ka - sys.highmem_base;
}

// Converts physical address to kernel address.
uintptr pa2ka(uintptr pa) {
    return pa + sys.highmem_base;
}

// Converts a kernel address to a physical address if the kernel address is
// higher than sys.highmem_base (a valid kernel address), otherwise returns the
// address as-is (i.e., this converts kernel and physical addresses to physical
// addresses).
uintptr kpa2pa(uintptr kpa) {
    if (kpa >= sys.highmem_base) {
        return ka2pa(kpa);
    }
    return kpa;
}

// Converts a physical address to a kernel address if in the kernel, or a
// physical address if in the monitor (where kernel addresses don't exist).
uintptr pa2kpa(uintptr pa) {
    version (monitor) {
        return pa;
    } else {
        return pa2ka(pa);
    }
}

// Virtual memory permissions.
enum Perm {
    r = 1 << 0, // read
    w = 1 << 1, // write
    x = 1 << 2, // execute
    u = 1 << 3, // user-accessible
    cow = 1 << 4, // copy-on-write

    rw  = r | w,
    rwx = rw | x,
    urx = u | r | x,
    urw  = u | rw,
    urwx = urw | x,
}

struct VaMapping {
    uintptr va;
    Pte* pte;
    size_t size;
    uintptr pa() { return pte.pa | (va & (size-1)); }
    Perm perm()  { return pte.perm; }

    uintptr ka() {
        return pa2ka(pa);
    }

    bool read()  { return (pte.perm & Perm.r) != 0; }
    bool write() { return (pte.perm & Perm.w) != 0; }
    bool exec()  { return (pte.perm & Perm.x) != 0; }
    bool user()  { return (pte.perm & Perm.u) != 0; }
    bool cow()   { return (pte.perm & Perm.cow) != 0; }
}

import kernel.arch;
import ulib.option;

Opt!(VaMapping) lookup(Pagetable* pt, uintptr va) {
    Pte.Pg pgtype;
    Pte* pte = pt.walk(va, pgtype);
    if (!pte || !pte.leaf(pgtype)) {
        return Opt!(VaMapping).none;
    }
    size_t size = Pagetable.level2size(pgtype);
    return Opt!(VaMapping)(VaMapping(va, pte, size));
}

import kernel.alloc;
import kernel.page;

bool mappg(Pagetable* pt, uintptr va, uintptr pa, Perm perm) {
    if (!pt.map(va, pa, Pte.Pg.normal, perm, &sys.allocator))
        return false;
    pages[pa / sys.pagesize].lock();
    (cast() pages[pa / sys.pagesize]).refcount++;
    pages[pa / sys.pagesize].unlock();
    return true;
}

void unmappg(Pagetable* pt, uintptr va, bool free) {
    auto level = Pte.Pg.normal;
    Pte* pte = pt.walk!(void, false)(va, level, null);
    if (!pte) {
        return;
    }
    pages[pte.pa / sys.pagesize].lock();
    (cast() pages[pte.pa / sys.pagesize]).refcount--;
    if (free && pages[pte.pa / sys.pagesize].refcount == 0) {
        kfree(cast(void*) pa2ka(pte.pa));
    }
    pages[pte.pa / sys.pagesize].unlock();
    pte.data = 0;
}

import ulib.math : align_off;
import libc;

// Utility functions for managing memory that is mapped in a pagetable.

// Allocate/map a new region from va_start to va_end.
uintptr alloc(Pagetable* pt, uintptr va_start, uintptr va_end, Perm perm) {
    if (va_end < va_start)
        return va_start;
    va_start += align_off(va_start, sys.pagesize);
    for (uintptr va = va_start; va < va_end; va += sys.pagesize) {
        void* mem = kalloc(sys.pagesize);
        if (!mem) {
            cast() dealloc(pt, va_start, va);
            return 0;
        }
        memset(mem, 0, sys.pagesize);
        if (!pt.mappg(va, ka2pa(cast(uintptr) mem), perm)) {
            kfree(mem);
            cast() dealloc(pt, va_start, va);
            return 0;
        }
    }
    return va_end;
}

// Deallocate/unmap the region from va_start to va_end.
uintptr dealloc(Pagetable* pt, uintptr va_start, uintptr va_end) {
    if (va_start >= va_end)
        return va_end;

    va_start += align_off(va_start, sys.pagesize);
    va_end += align_off(va_end, sys.pagesize);

    if (va_start < va_end) {
        size_t npages = (va_end - va_start) / sys.pagesize;
        unmap(pt, va_start, npages, true);
    }

    return va_start;
}

// Unmap `npages` pages starting at `va`. Pages are freed if `free`.
void unmap(Pagetable* pt, uintptr va, size_t npages, bool free) {
    for (uintptr a = va; a < va + npages * sys.pagesize; va += sys.pagesize) {
        pt.unmappg(a, free);
    }
}

// Pagetable iterator (could use some cleanup).

alias VmRange = LevelRange!(Pte.Pg.max);

struct LevelRange(Pte.Pg level) {
    import bits = ulib.bits;

    enum lastlevel = level == Pte.Pg.min;

    Pagetable* pt;
    uint idx;
    static if (!lastlevel) {
        LevelRange!(Pte.down(level)) next;
    }

    this(Pagetable* pt) {
        this.pt = pt;
    }

    this(Pagetable* pt, uintptr va) {
        this.pt = pt;
        this.idx = cast(uint) bits.get(va, 38, 0) / Pagetable.level2size(level);
        static if (!lastlevel) {
            this.next = typeof(this.next)(pt, va % Pagetable.level2size(level));
        }
    }

    // reached the last pte
    bool ended() {
        return idx >= pt.ptes.length;
    }

    bool empty() {
        return !get_mapping().has();
    }

    VaMapping front() {
        return get_mapping().get();
    }

    Opt!(VaMapping) get_mapping() {
        if (ended()) {
            return Opt!(VaMapping).none;
        }
        Pte* pte = &pt.ptes[idx];
        if (pte.leaf(level) && pte.valid()) {
            return Opt!(VaMapping)(VaMapping(
                bits.sext!(long, ulong)(idx * Pagetable.level2size(level), 39),
                pte,
                Pagetable.level2size(cast(Pte.Pg) level),
            ));
        }
        static if (!lastlevel) {
            if (pte.valid() && next.pt == null) {
                next = LevelRange!(Pte.down(level))(cast(Pagetable*) pa2ka(pt.ptes[idx].pa()));
            }
            if (pte.valid() && !next.empty()) {
                auto nf = next.front();
                nf.va += idx * Pagetable.level2size(level);
                return Opt!(VaMapping)(nf);
            }
        }
        do {
            idx++;
        } while (!ended() && !pt.ptes[idx].valid());
        static if (!lastlevel) {
            if (!ended() && pt.ptes[idx].valid() && !pt.ptes[idx].leaf(level)) {
                next = LevelRange!(Pte.down(level))(cast(Pagetable*) pa2ka(pt.ptes[idx].pa()));
            }
        }
        return get_mapping();
    }

    void popFront() {
        static if (!lastlevel) {
            if (!next.empty()) {
                next.popFront();
            } else {
                idx++;
            }
        } else {
            idx++;
        }
    }
}
