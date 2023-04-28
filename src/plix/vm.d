module plix.vm;

import sys = plix.sys;

// Returns true if va is a kernel address.
bool iska(uintptr va) {
    return va >= sys.highmem_base;
}

// Converts kernel address to physical address.
uintptr ka2pa(uintptr ka) {
    return ka - sys.highmem_base;
}

// Converts a physical address to a high kernel address.
uintptr pa2hka(uintptr pa) {
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
uintptr pa2ka(uintptr pa) {
    version (monitor) {
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
