module kernel.arch.riscv64.timer;

import core.volatile;

import kernel.board;
import kernel.arch.riscv64.csr;

import sbi = kernel.arch.riscv64.sbi;

struct Timer {
    private static void delay_cycles(ulong t) {
        ulong rb = Csr.cycle;
        while (1) {
            ulong ra = Csr.cycle;
            if ((ra - rb) >= t) {
                break;
            }
        }
    }

    private static void delay_time(ulong t) {
        ulong rb = volatile_ld(Clint.mtime);
        while (1) {
            ulong ra = volatile_ld(Clint.mtime);
            if ((ra - rb) >= t) {
                break;
            }
        }
    }

    static void delay_us(ulong t) {
        delay_time(t * (System.mtime_freq / 1_000_000));
    }

    enum interval = 100000;

    static ulong freq() {
        return System.mtime_freq;
    }

    static ulong time() {
        return volatile_ld(Clint.mtime);
    }

    static void intr() {
        intr(interval);
    }

    static void intr(ulong us) {
        ulong next = time() + freq() / 1000000 * us;
        sbi.Timer.set_timer(next);
    }
}
