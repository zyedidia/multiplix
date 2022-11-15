module kernel.vm;

enum highmem_base = 0xFFFF_FFC0_0000_0000;

uintptr ka2pa(uintptr ka) {
    return ka - highmem_base;
}

uintptr pa2ka(uintptr pa) {
    return pa + highmem_base;
}
