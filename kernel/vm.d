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
    // TODO: fix the build system so we can have this working correctly
    return pa;
    /* version (monitor) { */
    /*     return pa; */
    /* } else { */
    /*     return pa2ka(pa); */
    /* } */
}
