module plix.dev.reboot.bcm;

import core.volatile : vld, vst;

import plix.arch.cache : device_fence;
import plix.board : uart;
import plix.panic : _halt;

struct BcmReboot {
    uintptr pm_rstc;
    uintptr pm_wdog;

    noreturn shutdown() {
        reboot();
    }

    noreturn reboot() {
        uart.tx_flush();
        device_fence();

        enum pm_password = 0x5a000000;
        enum pm_rstc_wrcfg_full_reset = 0x20;

        vst(cast(uint*) pm_wdog, pm_password | 1);
        vst(cast(uint*) pm_rstc, pm_password | pm_rstc_wrcfg_full_reset);

        _halt();
    }
}

