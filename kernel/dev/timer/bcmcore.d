module kernel.dev.timer.bcmcore;

import core.volatile;
import core.sync;

import kernel.cpu;

struct BcmCoreTimer(uintptr base) {
    static void enable_irq() {
        device_fence();
        volatile_st(cast(uint*) (base + 0x40 + 4 * cpuinfo.coreid), 0b0010);
        device_fence();
    }

    static void enable_pmu_irq() {
        device_fence();
        volatile_st(cast(uint*) (base + 0x10), 1);
        device_fence();
    }

    static ulong time() {
        device_fence();
        uint ls32 = volatile_ld(cast(uint*) (base + 0x1C));
        uint ms32 = volatile_ld(cast(uint*) (base + 0x20));
        device_fence();
        return ((cast(ulong) ms32) << 32) | ls32;
    }
}
