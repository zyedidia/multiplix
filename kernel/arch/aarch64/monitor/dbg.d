module kernel.arch.aarch64.monitor.dbg;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;

import fwi = kernel.arch.aarch64.fwi;

import bits = ulib.bits;

import kernel.cpu;
import kernel.board;

import kernel.check.fence;

shared FenceChecker[Machine.ncores] chks;
__gshared bool[Machine.ncores] enabled;

struct ExtDebug {
    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case fwi.Debug.Fid.enable:
                SysReg.mdscr_el1 = bits.set(SysReg.mdscr_el1, Mdscr.ss_bit);
                place_breakpoint(SysReg.elr_el2);
                place_watchpoint(0, DbgLsc.rdwr);
                enabled[cpu.coreid] = true;
                break;
            case fwi.Debug.Fid.disable:
                clear_breakpoints();
                clear_ss();
                *out_val = enabled[cpu.coreid];
                enabled[cpu.coreid] = false;
                break;
            case fwi.Debug.Fid.alloc_heap:
                import sys = kernel.sys;
                sys.allocator.__ctor(cast(ubyte*) regs.x0, regs.x1);
                for (int i = 0; i < chks.length; i++) {
                    assert((cast()chks[i]).setup());
                }
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

    static void handle_watchpoint(uintptr epc, uintptr addr, Regs* regs) {
        import ulib.print;
        printf("watch event on address: %lx\n", addr);
        toggle_watchpoints();
    }

    static void handle_ss(uintptr epc, Regs* regs) {
        import ulib.print;
        single_step();
    }

    static void place_breakpoint(uintptr addr) {
        SysReg.dbgbvr0_el1 = addr;
        SysReg.dbgbcr0_el1 = bits.write(0, 23, 20, Dbgbcr.unlinked_insn) | Dbgbcr.aarch64 | Dbgbcr.el1_el0 | Dbgbcr.e;
    }

    static void place_watchpoint(uintptr addr, uint lsc) {
        SysReg.dbgwvr0_el1 = addr;
        SysReg.dbgwcr0_el1 = lsc << 3 | 0b11111111 << 5 | Dbgbcr.el1_el0 | Dbgbcr.e;
    }

    static void single_step() {
        SysReg.spsr_el2 = bits.set(SysReg.spsr_el2, Spsr.ss_bit);
    }

    static void clear_breakpoints() {
        SysReg.dbgbcr0_el1 = 0;
    }

    static void toggle_watchpoints() {
        if ((SysReg.dbgwcr0_el1 & 1) == 1)
            SysReg.dbgwcr0_el1 = SysReg.dbgwcr0_el1 & ~1;
        else
            SysReg.dbgwcr0_el1 = SysReg.dbgwcr0_el1 | 1;
    }

    static void clear_ss() {
        SysReg.spsr_el2 = bits.clear(SysReg.spsr_el2, Spsr.ss_bit);
        SysReg.mdscr_el1 = bits.clear(SysReg.mdscr_el1, Mdscr.ss_bit);
    }
}
