module kernel.vm;

import sys = kernel.sys;

import kernel.arch;
import kernel.alloc;

import ulib.option;
import ulib.memory;
import ulib.math : align_off;

import bits = ulib.bits;

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

struct VaMapping {
    uintptr va;
    uintptr pa;
    size_t size;
    bool read;
    bool write;
    bool exec;
    bool user;

    this(uintptr va, size_t size, Pte* pte) {
        this.va = va;
        this.pa = pte.pa();
        this.size = size;
        this.read = pte.read() != 0;
        this.write = pte.write() != 0;
        this.exec = pte.exec() != 0;
        this.user = pte.user() != 0;
    }

    uintptr ka() {
        return pa2ka(pa);
    }
}

// Look up a virtual address in a pagetable and return the VaMapping.
Opt!(VaMapping) lookup(Pagetable* pt, uintptr va) {
    Pte.Pg pgtype;
    Pte* pte = pt.walk(va, pgtype);
    if (!pte || !pte.leaf(pgtype)) {
        return Opt!(VaMapping).none;
    }
    size_t size = Pagetable.level2size(pgtype);
    return Opt!(VaMapping)(VaMapping(va, size, pte));
}

void unmap(Pagetable* pt, uintptr va, Pte.Pg pgtyp, bool free) {
    Pte* pte = pt.walk!(void, false)(va, pgtyp, null);
    if (!pte) {
        return;
    }
    if (free) {
        kfree(cast(void*) pa2ka(pte.pa));
    }
    pte.data = 0;
}

uintptr uvmalloc(Pagetable* pt, uintptr oldva, uintptr newva, ubyte perm) {
    if (newva < oldva)
        return oldva;
    oldva += align_off(oldva, sys.pagesize);
    for (uintptr va = oldva; va < newva; va += sys.pagesize) {
        void* mem = kalloc(sys.pagesize);
        if (!mem) {
            cast() uvmdealloc(pt, va, oldva);
            return 0;
        }
        memset(mem, 0, sys.pagesize);
        if (!pt.map(va, ka2pa(cast(uintptr) mem), Pte.Pg.normal, perm, &sys.allocator)) {
            kfree(mem);
            cast() uvmdealloc(pt, va, oldva);
            return 0;
        }
    }
    return newva;
}

uintptr uvmdealloc(Pagetable* pt, uintptr oldva_, uintptr newva_) {
    if (newva_ >= oldva_)
        return oldva_;

    newva_ += align_off(newva_, sys.pagesize);
    oldva_ += align_off(oldva_, sys.pagesize);

    if (newva_ < oldva_) {
        size_t npages = (oldva_ - newva_) / sys.pagesize;
        uvmunmap(pt, newva_, npages, true);
    }

    return newva_;
}

void uvmunmap(Pagetable* pt, uintptr va, size_t npages, bool free) {
    for (uintptr a = va; a < va + npages * sys.pagesize; va += sys.pagesize) {
        pt.unmap(a, Pte.Pg.normal, free);
    }
}

// Pagetable range (iterator) API.
alias Range = LevelRange!(Pte.Pg.max);

Range range(Pagetable* pt) {
    return Range(pt, 0);
}

struct LevelRange(Pte.Pg level) {
    enum lastlevel = level == Pte.Pg.min;

    Pagetable* pt;
    uint idx;
    static if (!lastlevel) {
        LevelRange!(Pte.down(level)) next;
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
                bits.sext!(long, ulong)(idx * Pagetable.level2size(cast(Pte.Pg) level), 39),
                Pagetable.level2size(cast(Pte.Pg) level),
                pte,
            ));
        }
        static if (!lastlevel) {
            if (pte.valid() && next.pt == null) {
                next = LevelRange!(Pte.down(level))(cast(Pagetable*) pa2ka(pt.ptes[idx].pa()));
            }
            if (pte.valid() && !next.empty()) {
                auto nf = next.front();
                nf.va += idx * Pagetable.level2size(cast(Pte.Pg) level);
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
