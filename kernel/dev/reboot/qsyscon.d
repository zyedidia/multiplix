module kernel.dev.reboot.qsyscon;

import core.volatile;

// Qemu syscon device.
struct QemuSyscon(uintptr base) {
    static noreturn shutdown() {
        volatile_st(cast(uint*) base, 0x5555);
        _halt();
    }

    static noreturn reboot() {
        volatile_st(cast(uint*) base, 0x7777);
        _halt();
    }
}
