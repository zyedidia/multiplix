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

    static ulong time_fn(ulong iters)(void function() fn) {
        auto start = arch.Timer.cycles();
        static foreach (j; 0 .. iters) {
            fn();
        }
        auto end = arch.Timer.cycles();
        return end - start;
    }
}
