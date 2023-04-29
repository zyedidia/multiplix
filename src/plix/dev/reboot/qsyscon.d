module plix.dev.reboot.qsyscon;

import core.volatile : vld, vst;
import plix.panic : _halt;

// Qemu syscon device.
struct QemuSyscon {
    uintptr base;

    noreturn shutdown() {
        vst(cast(uint*) base, 0x5555);
        _halt();
    }

    noreturn reboot() {
        vst(cast(uint*) base, 0x7777);
        _halt();
    }
}
