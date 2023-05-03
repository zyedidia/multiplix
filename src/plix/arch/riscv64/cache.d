module plix.arch.riscv64.cache;

pragma(inline, true)
void device_fence() {
    asm {
        "fence" ::: "memory";
    }
}

pragma(inline, true)
void inv_dcache(void* start, usize size) {
}

pragma(inline, true)
void clean_dcache(void* start, usize size) {
}

pragma(inline, true)
void sync_fence() {
    asm {
        "fence" ::: "memory";
    }
}

pragma(inline, true)
void sync_idmem(void* start, usize size) {
    insn_fence();
}

pragma(inline, true)
void insn_fence() {
    asm {
        "fence.i" ::: "memory";
    }
}

pragma(inline, true)
void vm_fence() {
    asm {
        "sfence.vma";
    }
}
