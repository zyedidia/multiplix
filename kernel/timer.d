module kernel.timer;

import arch = kernel.arch;

struct Timer {
    static void delay_nops(ulong n) {
        for (ulong i = 0; i < n; i++) {
            asm {
                "nop";
            }
        }
    }
    static void delay_us(ulong us) {
        arch.Timer.delay_us(us);
    }
}
