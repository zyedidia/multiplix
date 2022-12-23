module kernel.dev.reboot.qsyscon;

import core.volatile;

// Qemu syscon device.
struct QemuSyscon(uintptr base) {
    static void shutdown() {
        volatileStore(cast(uint*)base, 0x5555);
    }

    static void reboot() {
        volatileStore(cast(uint*)base, 0x7777);
    }
}
