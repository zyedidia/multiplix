module kernel.arch.riscv64.monitor.dbg;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;

import sbi = kernel.arch.riscv64.sbi;

import bits = ulib.bits;

struct ExtDebug {
    enum nbrk = 2; // number of hardware breakpoints per hart

    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Debug.Fid.step_start:
                place_mismatch_breakpoint(Csr.mepc);
                break;
            case sbi.Debug.Fid.step_start_at:
                place_breakpoint(regs.a0);
                break;
            case sbi.Debug.Fid.step_stop:
                clear_breakpoints();
                break;
            default:
                return false;
        }
        return true;
    }

    static void handle_breakpoint(uintptr epc, Regs* regs) {
        import io = ulib.io;
        io.writeln("reached breakpoint: ", cast(void*) epc);
        place_mismatch_breakpoint(epc);
    }

    static void place_breakpoint(uintptr addr) {
        Csr.tselect = 0;
        Csr.tdata1 = 0b011100;
        Csr.tdata2 = addr;
    }

    static void place_mismatch_breakpoint(uintptr addr) {
        // break on >= addr + 2
        Csr.tselect = 0;
        Csr.tdata1 = bits.write(0b011100, 10, 7, 2);
        Csr.tdata2 = addr + 2;

        // break on < addr
        Csr.tselect = 1;
        Csr.tdata1 = bits.write(0b011100, 10, 7, 3);
        Csr.tdata2 = addr;
    }

    static void clear_breakpoints() {
        for (uint i = 0; i < nbrk; i++) {
            Csr.tselect = i;
            Csr.tdata1 = 0;
        }
    }
}
