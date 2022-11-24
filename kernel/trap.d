module kernel.trap;

import arch = kernel.arch;

struct Trap {
    static bool wasEnabled;
    static int noff;

    static void pushDisable() {
        bool old = arch.Trap.enabled();
        arch.Trap.disable();
        if (noff == 0) {
            wasEnabled = old;
        }
        noff++;
    }

    static void popDisable() {
        noff--;
        if (noff == 0 && wasEnabled) {
            arch.Trap.enable();
        }
    }
}
