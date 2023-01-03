module kernel.arch.riscv64.monitor.hart;

import sbi = kernel.arch.riscv64.sbi;

import kernel.arch.riscv64.regs;

// TODO
struct ExtHart {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Hart.Fid.start:
                break;
            default:
                return false;
        }
        return true;
    }
}
