module kernel.dev.syscon;

import core.volatile;

struct SysCon(uint* base) {
    static void shutdown() {
        volatileStore(base, 0x5555);
    }

    static void reboot() {
        volatileStore(base, 0x7777);
    }
}
