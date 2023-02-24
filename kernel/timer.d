module kernel.timer;

import kernel.arch;

struct Timer {
    // Forward all functions from ArchTimer.
    enum ArchTimer timer = ArchTimer();
    alias timer this;

    // Delay until `t` ticks have expired from `tfn`.
    private static void delay(alias tfn)(ulong t) {
        ulong rb = tfn();
        while (true) {
            ulong ra = tfn();
            if ((ra - rb) >= t) {
                break;
            }
        }
    }

    // Delay for `cyc` cycles.
    static void delay_cycles(ulong cyc) {
        delay!(ArchTimer.cycles)(cyc);
    }

    // Delay for `us` microseconds.
    static void delay_us(ulong us) {
        delay!(ArchTimer.time)(us * ArchTimer.freq() / 1_000_000);
    }

    // Delay for `ms` milliseconds.
    static void delay_ms(ulong ms) {
        delay_us(ms * 1000);
    }

    static ulong us_since(ulong prev_time) {
        return (ArchTimer.time - prev_time) * 1_000_000 / ArchTimer.freq();
    }

    // Delay for `n` nops.
    static void delay_nops(ulong n) {
        for (ulong i = 0; i < n; i++) {
            asm {
                "nop";
            }
        }
    }

    // Timing function for micro-benchmarks.
    static ulong time_fn(ulong iters)(void function() fn) {
        auto start = ArchTimer.cycles();
        static foreach (j; 0 .. iters) {
            fn();
        }
        auto end = ArchTimer.cycles();
        return end - start;
    }
}
