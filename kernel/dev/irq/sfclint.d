module kernel.dev.irq.sfclint;

struct SifiveClint(uintptr base) {
    enum ulong* mtime = cast(ulong*) (base + 0xBFF8);

    static ulong* msip(ulong n) {
        return cast(ulong*) (base + 8 * n);
    }

    static ulong* mtimecmp(ulong n) {
        return cast(ulong*) (base + 0x4000 + 8 * n);
    }
}
