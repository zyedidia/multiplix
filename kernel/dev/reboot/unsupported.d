module kernel.dev.reboot.unsupported;

import core.exception;

struct Unsupported {
    static noreturn shutdown() {
        panic("reboot not supported");
    }

    static noreturn reboot() {
        shutdown();
    }
}
