module kernel.vm;

import sys = kernel.sys;

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

    rw  = r | w,
    rwx = rw | x,
    urw  = u | rw,
    urwx = urw | x,
}

struct VaMapping {
    uintptr va;
    uintptr pa;
    size_t size;
    Perm perm;
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
    return Opt!(VaMapping)(VaMapping(va, pte.pa, size, pte.perm));
}

import kernel.alloc;

void unmappg(Pagetable* pt, uintptr va, Pte.Pg pgtyp, bool free) {
    Pte* pte = pt.walk!(void, false)(va, pgtyp, null);
    if (!pte) {
        return;
    }
    if (free) {
        kfree(cast(void*) pa2ka(pte.pa));
    }
    // TODO: need to invalidate this entry from TLB when we switch to this pagetable
    pte.data = 0;
}

import ulib.math : align_off;
import ulib.memory;

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
        if (!pt.map(va, ka2pa(cast(uintptr) mem), Pte.Pg.normal, perm, &sys.allocator)) {
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
        pt.unmappg(a, Pte.Pg.normal, free);
    }
}
