module kernel.dev.reboot.qsyscon;

import core.volatile;

// Qemu syscon device.
struct QemuSyscon(uintptr base) {
    static noreturn shutdown() {
        vst(cast(uint*) base, 0x5555);
        _halt();
    }

    static noreturn reboot() {
        vst(cast(uint*) base, 0x7777);
        _halt();
    }
}
