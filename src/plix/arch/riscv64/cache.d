module plix.arch.riscv64.cache;

void device_fence() {
    asm {
        "fence" ::: "memory";
    }
}
