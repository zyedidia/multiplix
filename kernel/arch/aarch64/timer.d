module kernel.arch.aarch64.timer;

import kernel.arch.aarch64.sysreg;

struct Timer {
    static void delay_us(ulong us) {
        // get the current counter frequency
        const ulong f = SysReg.cntfrq_el0;
        ulong t = SysReg.cntpct_el0;
        t += ((f / 1000) * us) / 1000;
        ulong r = void;
        do {
            r = SysReg.cntpct_el0;
        } while (r < t);
    }

    static ulong freq() {
        return SysReg.cntfrq_el0;
    }

    static ulong cycles() {
        return SysReg.pmccntr_el0;
    }

    enum interval = 100000;
    static void intr() {
        intr(interval);
    }

    static void intr(ulong us) {
        SysReg.cntp_tval_el0 = freq() / 1000000 * us;
        SysReg.cntp_ctl_el0 = 1;
    }
}
