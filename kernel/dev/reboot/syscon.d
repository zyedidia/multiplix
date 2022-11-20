module kernel.dev.reboot.syscon;

import core.volatile;

// Qemu syscon device.
struct SysCon(uint* base) {
    static void shutdown() {
        volatileStore(base, 0x5555);
    }

    static void reboot() {
        volatileStore(base, 0x7777);
    }
}

