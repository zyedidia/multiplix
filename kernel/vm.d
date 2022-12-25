module kernel.vm;

import sys = kernel.sys;

uintptr ka2pa(uintptr ka) {
    return ka - sys.highmem_base;
}

uintptr pa2ka(uintptr pa) {
    return pa + sys.highmem_base;
}

uintptr kpa2pa(uintptr kpa) {
    if (kpa >= sys.highmem_base) {
        return ka2pa(kpa);
    }
    return kpa;
}
