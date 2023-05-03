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

pragma(inline, true)
private void clean_dcache(ubyte* start, usize size) {
    for (usize i = 0; i < size; i++) {
        asm {
            "dc cvau, %0" :: "r"(start + i);
        }
    }
}

pragma(inline, true)
private void clean_icache(ubyte* start, usize size) {
    for (usize i = 0; i < size; i++) {
        asm {
            "ic ivau, %0" :: "r"(start + i);
        }
    }
}

pragma(inline, true)
private void sync_fence() {
    asm {
        "dsb ish" ::: "memory";
    }
}

pragma(inline, true)
void sync_idmem(ubyte* start, usize size) {
    clean_dcache(start, size);
    sync_fence();
    clean_icache(start, size);
    sync_fence();
    insn_fence();
}

pragma(inline, true)
void insn_fence() {
    asm {
        "isb sy" ::: "memory";
    }
}
