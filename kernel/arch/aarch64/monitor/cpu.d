module kernel.arch.aarch64.monitor.cpu;

import core.volatile;
import core.sync;

import kernel.arch.aarch64.sysreg;

import fwi = kernel.arch.aarch64.fwi;

import kernel.arch.aarch64.regs;

extern (C) extern __gshared uint wakeup;

struct ExtCpu {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case fwi.Cpu.Fid.start_all_cores:
                // Caches must not yet be enabled so that the store to
                // wakeup goes directly to memory. Alternatively we could
                // flush the cache after writing.
                volatile_st(&wakeup, 1);
                device_fence();
                asm { "sev"; }
                break;
            case fwi.Cpu.Fid.enable_vm:
                void fence() {
                    pragma(inline, true);
                    asm {
                        "dsb sy";
                        "isb";
                    }
                }
                SysReg.mair_el2 = (Mair.device_ngnrne << Mair.device_idx * 8) | (Mair.normal_cacheable << Mair.normal_idx * 8);
                SysReg.tcr_el2 = Tcr.t0sz!(25) | Tcr.t1sz!(25) | Tcr.tg0_4kb | Tcr.tg1_4kb | Tcr.ips_36 | Tcr.irgn | Tcr.orgn | Tcr.sh;
                SysReg.ttbr0_el2 = regs.x0;
                fence();
                SysReg.sctlr_el2 = SysReg.sctlr_el2 | Sctlr.mmu | Sctlr.icache | Sctlr.dcache; // enable mmu and caches
                fence();
                break;
            default:
                return false;
        }
        return true;
    }
}
