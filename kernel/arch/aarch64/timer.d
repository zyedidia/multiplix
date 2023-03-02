module kernel.arch.aarch64.timer;

import kernel.arch.aarch64.sysreg;

struct ArchTimer {
    static ulong freq() {
        return SysReg.cntfrq_el0;
    }

    static ulong time() {
        return SysReg.cntpct_el0;
    }

    static ulong cycles() {
        return SysReg.pmccntr_el0;
    }

    enum interval = 10000;

    static void intr() {
        intr(interval);
    }

    static void intr(ulong us) {
        SysReg.cntp_tval_el0 = freq() / 1_000_000 * us;
        SysReg.cntp_ctl_el0 = 1;
    }
}
