module kernel.arch.riscv64.monitor.clint;

// Clint location for the Sifive U74MC core complex.
// TODO: make this a device and move it into the board definition.
alias Clint = SifiveClint!(0x0200_0000);

struct SifiveClint(uintptr base) {
    enum ulong* mtime = cast(ulong*) (base + 0xBFF8);

    static ulong* mtimecmp(ulong n) {
        return cast(ulong*) (base + 0x4000 + 8 * n);
    }
}
