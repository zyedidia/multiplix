module kernel.arch.riscv64.timer;

import kernel.arch.riscv64.csr;
import sbi = kernel.arch.riscv64.sbi;

struct Timer {
    enum interval = 1000000;

    static ulong time() {
        return Csr.time;
    }

    static void delayTime(ulong t) {
        ulong rb = time();
        while (1) {
            ulong ra = time();
            if ((ra - rb) >= t) {
                break;
            }
        }
    }

    static ulong cycles() {
        return Csr.cycle;
    }

    static void intr() {
        intr(interval);
    }

    static void intr(ulong interval) {
        ulong next = time() + interval;
        sbi.Timer.setTimer(next);
    }
}
