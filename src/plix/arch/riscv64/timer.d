module plix.arch.riscv64.timer;

import plix.arch.riscv64.csr : Csr;
import plix.board : Machine, clint;

struct Timer {
    static void setup() {}

    static ulong cycles() {
        return Csr.cycle;
    }

    static ulong freq() {
        return Machine.mtime_freq;
    }

    static ulong time() {
        return clint.mtime;
    }

    static void intr(ulong us) {
        import plix.fwi : set_timer;

        ulong next = time() + freq() / 1_000_000 * us;
        set_timer(next);
    }
}

void monitor_set_timer(ulong stime) {
    import plix.board : clint;
    import plix.arch.riscv64.csr : Csr, Mip, Mie;
    import bits = core.bits;

    clint.wr_mtimecmp(Csr.mhartid, stime);
    Csr.mip_clear!(Mip.stip)();
    Csr.mie_set!(Mie.mtie)();
}
