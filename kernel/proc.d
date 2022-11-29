module kernel.proc;

import kernel.arch;
import kernel.alloc;

import sys = kernel.sys;
import vm = kernel.vm;

import ulib.memory;

struct Proc {
    enum stackva = 0x7fff0000;
    enum trapframeva = stackva - sys.pagesize;

    enum State {
        runnable,
        running,
    }

    Trapframe* trapframe;

    Pagetable* pt;
    State state;
    ubyte[] code;
    ubyte[] stack;

    static bool make(Proc* proc, immutable ubyte[] binary, uintptr baseva, uintptr entryva) {
        // TODO: use arena allocation to ease memory cleanup
        // allocate pagetable
        auto opt = kalloc!(Pagetable)();
        if (!opt.has()) {
            return false;
        }
        proc.pt = opt.get();
        // allocate physical space for binary, and copy it in
        auto opgs = kallocpage(binary.length);
        if (!opgs.get()) {
            kfree(cast(void*) proc.pt);
            return false;
        }
        proc.code = cast(ubyte[]) opgs.get()[0 .. binary.length];
        proc.code[0 .. $] = binary[0 .. $];
        // map newly allocated physical space to base va
        for (uintptr va = baseva, pa = vm.ka2pa(cast(uintptr) proc.code.ptr); va < baseva + binary.length; va += sys.pagesize, pa += sys.pagesize) {
            if (!proc.pt.map(va, pa, Pte.Pg.normal, Perm.urwx)) {
                // TODO: if failed, free memory
                return false;
            }
        }
        // map kernel
        for (uintptr pa = 0; pa < sys.memsizePhysical; pa += sys.gb!(1)) {
            proc.pt.mapGiga(vm.pa2ka(pa), pa, Perm.krwx);
        }
        // allocate stack/trapframe
        auto ostack = kallocpage(sys.pagesize * 2);
        if (!ostack.get()) {
            kfree(cast(void*) proc.pt);
            kfree(cast(void*) proc.code.ptr);
        }
        proc.stack = cast(ubyte[]) ostack.get()[0 .. sys.pagesize];
        proc.trapframe = cast(Trapframe*) ostack.get()[sys.pagesize .. sys.pagesize * 2];
        // map stack/trapframe
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) proc.stack.ptr), Pte.Pg.normal, Perm.urwx)) {
            // TODO: if failed, free memory
            return false;
        }
        if (!proc.pt.map(trapframeva, vm.ka2pa(cast(uintptr) proc.trapframe), Pte.Pg.normal, Perm.urwx)) {
            // TODO: if failed, free memory
            return false;
        }
        // initialize registers (stack, pc)
        memset(&proc.trapframe.regs, 0, Regs.sizeof);
        proc.trapframe.regs.sp = stackva + sys.pagesize;
        proc.trapframe.epc = entryva;
        proc.trapframe.p = proc;

        proc.state = State.runnable;

        return true;
    }
}
