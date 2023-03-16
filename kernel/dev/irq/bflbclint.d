module kernel.dev.irq.sfclint;

import core.volatile;
import kernel.arch.riscv64.csr;

struct BouffaloLabsClint(uintptr base) {
    static ulong time() {
        return Csr.time();
    }

    static ulong* msip(ulong n) {
        return cast(ulong*)(base + 8 * n);
    }

    static ulong mtimecmp(ulong n) {
        uint* p = cast(uint*)(base + 0x4000 + 8 * n);
        uint lo = vld(p);
        uint hi = vld(p + 1);
        return cast(ulong) hi << 32 | lo;
    }

    static void mtimecmp(ulong n, ulong x) {
        uint* p = cast(uint*)(base + 0x4000 + 8 * n);
        uint lo = x & 0xffffffff;
        uint hi = x >> 32 & 0xffffffff;
        vst(p, lo);
        vst(p + 1, hi);
    }
}
