module kernel.dev.reboot.qsyscon;

import core.volatile;

// Qemu syscon device.
struct QemuSyscon(uintptr base) {
    static void shutdown() {
        volatile_st(cast(uint*)base, 0x5555);
    }

    static void reboot() {
        volatile_st(cast(uint*)base, 0x7777);
    }
}
