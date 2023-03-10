module kernel.arch.riscv64.monitor.dbg;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;

import kernel.cpu;
import kernel.board;

import sbi = kernel.arch.riscv64.sbi;

import bits = ulib.bits;

__gshared FenceChecker[Machine.ncores] fchks;

struct ExtDebug {
    enum nbrk = 2; // number of hardware breakpoints per hart

    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            case sbi.Debug.Fid.enable:
                place_mismatch_breakpoint(Csr.mepc);
                break;
            case sbi.Debug.Fid.enable_at:
                place_breakpoint(regs.a0);
                break;
            case sbi.Debug.Fid.disable:
                clear_breakpoints();
                break;
            case sbi.Debug.Fid.alloc_heap:
                import sys = kernel.sys;
                sys.allocator.__ctor(cast(ubyte*) regs.a0, regs.a1);
                break;
            default:
                return false;
        }
        return true;
    }

    static void handle_breakpoint(uintptr epc, Regs* regs) {
        place_mismatch_breakpoint(epc);
    }

    static void handle_watchpoint(uintptr epc, uintptr va, Regs* regs) {

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

private ulong hash(uintptr key) {
    key ^= key >> 33;
    key *= 0xff51afd7ed558ccd;
    key ^= key >> 33;
    key *= 0xc4ceb9fe1a85ec53;
    key ^= key >> 33;
    return key;
}

private bool eq(uintptr a, uintptr b) {
    return a == b;
}

struct FenceChecker {
    import ulib.hashmap;
    import core.exception;
    Hashmap!(uintptr, bool, hash, eq) mem;

    void on_store(uintptr pa) {
        if (!mem.put(pa, true)) {
            panic("fence: out of memory");
        }
    }

    void on_exec(uintptr pa) {
        if (mem.get(pa, null)) {
            panicf("fence: executed %lx without preceding fence", pa);
        }
    }

    void on_fence() {
        mem.clear();
    }
}
