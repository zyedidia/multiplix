module plix.arch.aarch64.cache;

pragma(inline, true)
void device_fence() {
    asm {
        "dsb sy" ::: "memory";
    }
}

pragma(inline, true)
void inv_dcache(ubyte* start, usize size) {
    for (usize i = 0; i < size; i++) {
        asm {
            "dc civac, %0" :: "r"(start + i);
        }
    }
}
