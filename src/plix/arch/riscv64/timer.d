module plix.arch.riscv64.timer;

import plix.arch.riscv64.csr : Csr;
import plix.board : Machine, clint;

struct Timer {
    static void setup() {}

    static ulong cycles() {
        return Csr.cycle;
    }

    static ulong freq() {
        return Machine.mtime_freq;
    }

    static ulong time() {
        return clint.mtime;
    }

    enum time_slice_us = 10000;

    static void intr(ulong us) {
        // ulong next = time() + freq() / 1000000 * us;
        // Timer.set_timer(next);
    }
}
