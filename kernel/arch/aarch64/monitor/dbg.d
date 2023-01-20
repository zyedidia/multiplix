module kernel.arch.aarch64.dbg;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;

import fwi = kernel.arch.aarch64.fwi;

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
                break;
            default:
                return false;
        }
        return true;
    }

    import io = ulib.io;

    static void handle_breakpoint(uintptr epc, Regs* regs) {
        io.writeln("handle breakpoint: ", epc);
        place_mismatch_breakpoint(epc);
    }

    static void place_breakpoint(uintptr addr) {
        io.writeln("place breakpoint at: ", cast(void*) addr);
    }

    static void place_mismatch_breakpoint(uintptr addr) {
        io.writeln("place mismatch breakpoint at: ", cast(void*) addr);
    }

    static void clear_breakpoints() {
        io.writeln("clear breakpoints");
    }
}
