module kernel.arch.aarch64.dbg;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;

import fwi = kernel.arch.aarch64.fwi;

import bits = ulib.bits;

struct ExtDebug {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case fwi.Debug.Fid.step_start:
                place_breakpoint(SysReg.elr_el2);
                break;
            case fwi.Debug.Fid.step_start_at:
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

    import io = ulib.io;

    static void handle_breakpoint(uintptr epc, Regs* regs) {
        io.writeln("handle breakpoint: ", cast(void*) epc);
        clear_breakpoints();
        single_step();
    }

    static void handle_ss(uintptr epc, Regs* regs) {
        io.writeln("handle ss: ", cast(void*) epc);
        single_step();
    }

    static void place_breakpoint(uintptr addr) {
        io.writeln("place breakpoint at: ", cast(void*) addr);
        SysReg.dbgbvr0_el1 = addr;
        SysReg.dbgbcr0_el1 = bits.write(0, 23, 20, Dbgbcr.unlinked_insn) | Dbgbcr.aarch64 | Dbgbcr.el1_el0 | Dbgbcr.e;
    }

    static void single_step() {
        SysReg.spsr_el2 = bits.set(SysReg.spsr_el2, Spsr.ss);
        SysReg.mdscr_el1 = bits.set(SysReg.mdscr_el1, Mdscr.ss);
    }

    static void clear_breakpoints() {
        io.writeln("clear breakpoints");
        SysReg.dbgbcr0_el1 = 0;
    }

    static void clear_ss() {
        io.writeln("clear software step");
        SysReg.spsr_el2 = bits.clear(SysReg.spsr_el2, Spsr.ss);
        SysReg.mdscr_el1 = bits.clear(SysReg.mdscr_el1, Mdscr.ss);
    }
}
