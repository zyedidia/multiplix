module plix.dev.irq.clint;

import core.volatile : vld, vst;

struct Clint {
    uintptr base;

    private enum usize msip_off = 0x0;
    private enum usize mtimecmp_off = 0x4000;
    private enum usize mtime_off = 0xbff8;

    ulong mtime() {
        return vld(cast(ulong*) (base + mtime_off));
    }

    void mtime(ulong val) {
        vst(cast(ulong*) (base + mtime_off), val);
    }

    void wr_msip(ulong n, ulong val) {
        vst(cast(ulong*) (base + msip_off + 8 * n), val);
    }

    void wr_mtimecmp(ulong n, ulong val) {
        vst(cast(ulong*) (base + mtimecmp_off + 8 * n), val);
    }
}
