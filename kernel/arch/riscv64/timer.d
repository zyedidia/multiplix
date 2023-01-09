module kernel.arch.riscv64.timer;

import kernel.board;
import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.clint;

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

    static void delay_us(ulong t) {
        delay_cycles(t * System.cpu_freq_mhz);
    }

    enum interval = 1000000;

    static ulong freq() {
        return 10_000_000;
    }

    static ulong time() {
        return *Clint.mtime;
    }

    static void intr() {
        intr(interval);
    }

    static void intr(ulong us) {
        ulong next = time() + freq() / 1000000 * us;
        sbi.Timer.set_timer(next);
    }
}
