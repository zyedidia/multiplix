module kernel.arch.riscv64.monitor.hart;

import core.volatile;

import sbi = kernel.arch.riscv64.sbi;

import kernel.arch.riscv64.regs;

extern (C) extern __gshared uint wakeup;

struct ExtHart {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Hart.Fid.start:
                break;
            case sbi.Hart.Fid.start_all_cores:
                volatile_st(&wakeup, 1);
                break;
            default:
                return false;
        }
        return true;
    }
}
