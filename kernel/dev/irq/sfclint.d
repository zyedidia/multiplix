module kernel.dev.irq.sfclint;

import core.volatile;

struct SifiveClint(uintptr base) {
    static ulong time() {
        return vld(cast(ulong*)(base + 0xBFF8));
    }

    static ulong* msip(ulong n) {
        return cast(ulong*)(base + 8 * n);
    }

    static ulong mtimecmp(ulong n) {
        return vld(cast(ulong*)(base + 0x4000 + 8 * n));
    }

    static void mtimecmp(ulong n, ulong x) {
        vst(cast(ulong*)(base + 0x4000 + 8 * n), x);
    }
}
