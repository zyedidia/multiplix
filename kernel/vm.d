module kernel.vm;

uintptr ka2pa(uintptr ka) {
    return ka & ~(1UL << 63);
}
