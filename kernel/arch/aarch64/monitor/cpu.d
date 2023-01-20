module kernel.arch.aarch64.monitor.cpu;

import core.volatile;
import core.sync;

import fwi = kernel.arch.aarch64.fwi;

import kernel.arch.aarch64.regs;

extern (C) extern __gshared uint wakeup;

struct ExtCpu {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case fwi.Cpu.Fid.start_all_cores:
                volatile_st(&wakeup, 1);
                device_fence();
                asm { "sev"; }
                break;
            default:
                return false;
        }
        return true;
    }
}
