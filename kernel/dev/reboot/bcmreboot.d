module kernel.dev.reboot.bcmreboot;

import core.volatile;
import core.sync;
import kernel.board;

struct BcmReboot(uintptr pm_rstc, uintptr pm_wdog) {
    static noreturn shutdown() {
        reboot();
    }

    static noreturn reboot() {
        Uart.tx_flush();
        device_fence();

        enum pm_password = 0x5a000000;
        enum pm_rstc_wrcfg_full_reset = 0x20;

        volatile_st(cast(uint*)pm_wdog, pm_password | 1);
        volatile_st(cast(uint*)pm_rstc, pm_password | pm_rstc_wrcfg_full_reset);

        while (true) {
        }
    }
}
