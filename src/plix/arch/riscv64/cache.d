module plix.arch.riscv64.cache;

void device_fence() {
    asm {
        "fence" ::: "memory";
    }
}

void inv_dcache(ubyte* start, usize size) {
    assert(0, "inv_dcache(riscv64): unimplemented");
}
