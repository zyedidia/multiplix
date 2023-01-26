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

    static void delay_ms(ulong t) {
        delay_us(t * 1000);
    }

    static ulong time_fn(ulong iters, void function() fn) {
        ulong total = 0;
        for (ulong i = 0; i < iters; i++) {
            auto start = arch.Timer.cycles();
            fn();
            total += arch.Timer.cycles() - start;
        }
        return total;
    }
}
