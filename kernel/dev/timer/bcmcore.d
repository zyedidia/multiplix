module kernel.dev.timer.bcmcore;

import core.volatile;

import kernel.cpu;

struct BcmCoreTimer(uintptr base) {
    static void enable_irq() {
        volatile_st(cast(uint*) (base + 0x40 + 4 * cpuinfo.coreid), 0b0010);
    }

    static ulong time() {
        uint ls32 = volatile_ld(cast(uint*) (base + 0x1C));
        uint ms32 = volatile_ld(cast(uint*) (base + 0x20));
        return ((cast(ulong) ms32) << 32) | ls32;
    }
}
