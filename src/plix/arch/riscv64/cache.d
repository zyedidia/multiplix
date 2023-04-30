module plix.arch.riscv64.cache;

pragma(inline, true)
void device_fence() {
    asm {
        "fence" ::: "memory";
    }
}

void inv_dcache(ubyte* start, usize size) {
    assert(0, "inv_dcache(riscv64): unimplemented");
}

pragma(inline, true)
void sync_idmem(ubyte* start, usize size) {
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
