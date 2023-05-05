module plix.arch.aarch64.cache;

pragma(inline, true)
void device_fence() {
    asm {
        "dsb sy" ::: "memory";
    }
}

pragma(inline, true)
void inv_dcache(void* start, usize size) {
    for (usize i = 0; i < size; i++) {
        asm {
            "dc civac, %0" :: "r"(start + i);
        }
    }
}

pragma(inline, true)
void clean_dcache(void* start, usize size) {
    for (usize i = 0; i < size; i++) {
        asm {
            "dc cvau, %0" :: "r"(start + i);
        }
    }
}

pragma(inline, true)
void clean_icache(void* start, usize size) {
    for (usize i = 0; i < size; i++) {
        asm {
            "ic ivau, %0" :: "r"(start + i);
        }
    }
}

pragma(inline, true)
void sync_fence() {
    asm {
        "dsb ish" ::: "memory";
    }
}

pragma(inline, true)
void sync_idmem(void* start, usize size) {
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

pragma(inline, true)
void sysreg_fence() {
    asm {
        "dsb sy";
        "isb";
    }
}

pragma(inline, true)
void vm_fence() {
    asm {
        "dsb ish" ::: "memory";
        "tlbi vmalle1" ::: "memory";
        "dsb ish" ::: "memory";
        "isb" ::: "memory";
    }
}
