module kernel.arch.riscv64.monitor.timer;

import core.volatile;

import sbi = kernel.arch.riscv64.sbi;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;

import kernel.board;

import bits = ulib.bits;

struct ExtTimer {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Timer.Fid.set_timer:
                ulong stime_value = regs.a0;
                ulong id = Csr.mhartid;
                vst(Clint.mtimecmp(id), stime_value);
                Csr.mip = bits.clear(Csr.mip, Mip.stip);
                Csr.mie = bits.set(Csr.mie, Mie.mtie);
                break;
            default:
                return false;
        }
        return true;
    }
}
