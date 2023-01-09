module kernel.arch.aarch64.timer;

import kernel.arch.aarch64.sysreg;

struct Timer {
    static void delay_us(ulong us) {
        ulong f, t, r;
        // get the current counter frequency
        asm {
            // read the current counter
            "mrs %0, cntfrq_el0" : "=r"(f);
            // calculate expire value for counter
            "mrs %0, cntpct_el0" : "=r"(t);
        }
        t += ((f / 1000) * us) / 1000;
        do {
            asm {
                "mrs %0, cntpct_el0" : "=r"(r);
            }
        } while (r < t);
    }

    static ulong freq() {
        return SysReg.cntfrq_el0;
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
