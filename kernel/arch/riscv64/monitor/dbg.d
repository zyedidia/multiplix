module kernel.arch.riscv64.monitor.dbg;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;

import kernel.cpu;
import kernel.board;
import kernel.spinlock;

import sbi = kernel.arch.riscv64.sbi;

import bits = ulib.bits;

import kernel.check.fence;
import kernel.check.conc;
import kernel.check.vm;

shared FenceChecker[Machine.ncores] fence_cks;
__gshared ConcChecker conc_ck;
__gshared bool[Machine.ncores] enabled;
__gshared VmChecker[Machine.ncores] vm_cks;

struct ExtDebug {
    enum nbrk = 2; // number of hardware breakpoints per hart

    enum BrkType {
        read = 1 << 0,
        write = 1 << 1,
        exec = 1 << 2,

        rwx = read | write | exec,
        rw = read | write,
        wx = write | exec,
        x = exec,
    }

    enum Insn {
        fencei = 0x100f,
    }

    static bool handler(uint fid, Regs* regs, uint* out_val) {
        switch (fid) {
            import ulib.print;
            case sbi.Debug.Fid.enable:
                place_mismatch_breakpoint(Csr.mepc, BrkType.rw);
                enabled[cpu.coreid] = true;
                break;
            case sbi.Debug.Fid.disable:
                clear_breakpoints();
                *out_val = enabled[cpu.coreid];
                enabled[cpu.coreid] = false;
                break;
            case sbi.Debug.Fid.alloc_heap:
                import sys = kernel.sys;
                sys.allocator.__ctor(cast(ubyte*) regs.a0, regs.a1);
                for (int i = 0; i < Machine.ncores; i++) {
                    assert((cast()fence_cks[i]).setup());
                    vm_cks[i].setup();
                }
                break;
            case sbi.Debug.Fid.vm_check:
                if (enabled[cpu.coreid]) vm_cks[cpu.coreid].check_consistency();
                break;
            case sbi.Debug.Fid.vm_fence:
                if (enabled[cpu.coreid]) vm_cks[cpu.coreid].on_vmfence();
                break;
            case sbi.Debug.Fid.mark_alloc:
                break;
            case sbi.Debug.Fid.mark_free:
                break;
            default:
                return false;
        }
        return true;
    }

    static void handle_breakpoint(uintptr epc, Regs* regs) {
        place_mismatch_breakpoint(epc, BrkType.x);
        // auto epcpa = va2pa(epc);
        // fence_cks[cpu.coreid].on_exec(epc, epcpa);
        // if (load_insn(epcpa) == Insn.fencei) {
        //     fence_cks[cpu.coreid].on_fence();
        // }
    }

    static void handle_watchpoint(uintptr epc, uintptr va, Regs* regs) {
        place_mismatch_breakpoint(epc, BrkType.x);
        conc_ck.on_access(va, 1, epc);
        // auto pa = va2pa(va);
        // for (int i = 0; i < fence_cks.length; i++) {
        //     fence_cks[i].on_store(pa, epc);
        // }
    }

    static void place_breakpoint(uintptr addr, BrkType flags) {
        Csr.tselect = 0;
        Csr.tdata1 = 0b011000 | flags;
        Csr.tdata2 = addr;
    }

    static void place_mismatch_breakpoint(uintptr addr, BrkType flags) {
        // break on < addr
        Csr.tselect = 0;
        Csr.tdata1 = bits.write(0b011000 | flags, 10, 7, 3);
        Csr.tdata2 = addr;

        // break on >= addr + 2
        Csr.tselect = 1;
        Csr.tdata1 = bits.write(0b011000 | flags, 10, 7, 2);
        Csr.tdata2 = addr + 2;
    }

    static void clear_breakpoints() {
        Csr.tselect = 0;
        Csr.tdata1 = 0;
        Csr.tselect = 1;
        Csr.tdata1 = 0;
    }

    static uint load_insn(uintptr epcpa) {
        if (epcpa % 4 == 0) {
            return *(cast(uint*) epcpa);
        }
        return (*(cast(ushort*) epcpa)) | (*(cast(ushort*) epcpa + 1) << 16);
    }

    static uintptr va2pa(uintptr va) {
        import kernel.vm;
        import kernel.arch.riscv64.vm;
        Pagetable* pt = current_pt();
        auto map = pt.lookup(va);
        assert(map.has());
        return map.get().pa;
    }
}
