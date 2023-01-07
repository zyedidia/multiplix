module kernel.arch.riscv64.clint;

import kernel.vm;

// Clint location for the Sifive U74MC core complex.
// TODO: make this a device and move it into the board definition.
alias Clint = SifiveClint!(pa2ka(0x0200_0000));

struct SifiveClint(uintptr base) {
    enum ulong* mtime = cast(ulong*) (base + 0xBFF8);

    static ulong* msip(ulong n) {
        return cast(ulong*) (base + 8 * n);
    }

    static ulong* mtimecmp(ulong n) {
        return cast(ulong*) (base + 0x4000 + 8 * n);
    }
}
