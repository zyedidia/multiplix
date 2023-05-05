module plix.arch.aarch64.timer;

import plix.arch.aarch64.sysreg : SysReg;

struct Timer {
    static void setup() {
        // Enable cycle counter.
        SysReg.pmcr_el0 = 1;
        SysReg.pmcntenset_el0 = 1 << 31;
    }

    static ulong freq() {
        return SysReg.cntfrq_el0;
    }

    static ulong time() {
        return SysReg.cntpct_el0;
    }

    static ulong cycles() {
        return SysReg.pmccntr_el0;
    }

    enum time_slice_us = 10000;

    static void intr(ulong us) {
        SysReg.cntp_tval_el0 = freq() / 1_000_000 * us;
        SysReg.cntp_ctl_el0 = 1;
    }
}
