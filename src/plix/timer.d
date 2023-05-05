module plix.timer;

import arch = plix.arch.timer;

struct Timer {
    static void setup() {
        arch.Timer.setup();
    }

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
        delay!(arch.Timer.cycles)(cyc);
    }

    // Delay for `us` microseconds.
    static void delay_us(ulong us) {
        delay!(arch.Timer.time)(us * arch.Timer.freq() / 1_000_000);
    }

    // Delay for `ms` milliseconds.
    static void delay_ms(ulong ms) {
        delay_us(ms * 1000);
    }

    static ulong cycles() {
        return arch.Timer.cycles();
    }

    static ulong time() {
        return arch.Timer.time();
    }

    static ulong us_since(ulong prev_time) {
        return (arch.Timer.time - prev_time) * 1_000_000 / arch.Timer.freq();
    }

    // Delay for `n` nops.
    static void delay_nops(ulong n) {
        for (ulong i = 0; i < n; i++) {
            asm {
                "nop";
            }
        }
    }
}
