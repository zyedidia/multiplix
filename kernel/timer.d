module kernel.timer;

struct Timer {
    static void delay_cycles(ulong t) {
        for (ulong i = 0; i < t; i++) {
            asm {
                "nop";
            }
        }
    }
}
