module plix.dev.timer.bcmcore;

import core.volatile : vld, vst;
import plix.arch.cache : device_fence;
import plix.cpu : cpuid;

struct BcmCoreTimer {
    uintptr base;

    void enable_irq() {
        device_fence();
        vst(cast(uint*) (base + 0x40 + 4 * cpuid()), 0b0010);
        device_fence();
    }

    ulong time() {
        device_fence();
        uint ls32 = vld(cast(uint*) (base + 0x1C));
        uint ms32 = vld(cast(uint*) (base + 0x20));
        device_fence();
        return ((cast(ulong) ms32) << 32) | ls32;
    }
}
