module kernel.arch.riscv64.monitor.timer;

import sbi = kernel.arch.riscv64.sbi;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.monitor.clint;

struct ExtTimer {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Timer.Fid.set_timer:
                ulong stime_value = regs.a0;

                ulong id = Csr.mhartid;
                *Clint.mtimecmp(id) = *Clint.mtime + stime_value;

                break;
            default:
                return false;
        }
        return true;
    }
}
