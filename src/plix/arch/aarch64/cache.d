module plix.arch.aarch64.cache;

void device_fence() {
    asm {
        "dsb sy" ::: "memory";
    }
}
