module kernel.dev.reboot.unsupported;

import core.exception;

struct Unsupported {
    static void shutdown() {
        panic("reboot not supported");
    }

    static void reboot() {
        shutdown();
    }
}
