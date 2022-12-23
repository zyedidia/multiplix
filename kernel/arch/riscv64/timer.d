module kernel.arch.riscv64.timer;

import kernel.board;
import kernel.arch.riscv64.csr;

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
}
