module kernel.arch.aarch64.monitor.dbg;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;

import fwi = kernel.arch.aarch64.fwi;

import bits = ulib.bits;

struct ExtDebug {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case fwi.Debug.Fid.step_start:
                SysReg.mdscr_el1 = bits.set(SysReg.mdscr_el1, Mdscr.ss_bit);
                place_breakpoint(SysReg.elr_el2);
                break;
            case fwi.Debug.Fid.step_start_at:
                SysReg.mdscr_el1 = bits.set(SysReg.mdscr_el1, Mdscr.ss_bit);
                place_breakpoint(regs.x0);
                break;
            case fwi.Debug.Fid.step_stop:
                clear_breakpoints();
                clear_ss();
                break;
            default:
                return false;
        }
        return true;
    }

    static void handle_breakpoint(uintptr epc, Regs* regs) {
        clear_breakpoints();
        single_step();
    }

    static void handle_ss(uintptr epc, Regs* regs) {
        single_step();
    }

    static void place_breakpoint(uintptr addr) {
        SysReg.dbgbvr0_el1 = addr;
        SysReg.dbgbcr0_el1 = bits.write(0, 23, 20, Dbgbcr.unlinked_insn) | Dbgbcr.aarch64 | Dbgbcr.el1_el0 | Dbgbcr.e;
    }

    static void single_step() {
        SysReg.spsr_el2 = bits.set(SysReg.spsr_el2, Spsr.ss_bit);
    }

    static void clear_breakpoints() {
        SysReg.dbgbcr0_el1 = 0;
    }

    static void clear_ss() {
        SysReg.spsr_el2 = bits.clear(SysReg.spsr_el2, Spsr.ss_bit);
        SysReg.mdscr_el1 = bits.clear(SysReg.mdscr_el1, Mdscr.ss_bit);
    }
}
