module kernel.arch.riscv64.timer;

import core.volatile;

import kernel.board;
import kernel.arch.riscv64.csr;

import sbi = kernel.arch.riscv64.sbi;

struct ArchTimer {
    static ulong cycles() {
        return Csr.cycle;
    }

    static ulong freq() {
        return Machine.mtime_freq;
    }

    static ulong time() {
        return vld(Clint.mtime);
    }

    enum interval = 100000;

    static void intr() {
        intr(interval);
    }

    static void intr(ulong us) {
        ulong next = time() + freq() / 1000000 * us;
        sbi.Timer.set_timer(next);
    }
}
