module kernel.proc;

import kernel.arch;
import kernel.alloc;

import sys = kernel.sys;
import vm = kernel.vm;

import ulib.memory;

struct Proc {
    enum stackva = 0x7fffffff;

    enum State {
        runnable,
        running,
    }

    Trapframe trapframe;

    Pagetable* pt;
    Regs regs;
    State state;
    byte[] code;
    byte[] stack;

    static bool make(Proc* proc, byte[] binary, uintptr baseva, uintptr entryva) {
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
        proc.code = cast(byte[]) opgs.get()[0 .. binary.length];
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
        // allocate stack
        auto ostack = kallocpage();
        if (!ostack.get()) {
            kfree(cast(void*) proc.pt);
            kfree(cast(void*) proc.code.ptr);
        }
        proc.stack = cast(byte[]) ostack.get()[0 .. sys.pagesize];
        // map stack
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) proc.stack.ptr), Pte.Pg.normal, Perm.urwx)) {
            // TODO: if failed, free memory
            return false;
        }
        // initialize registers (stack, pc)
        memset(&proc.regs, 0, Regs.sizeof);
        proc.regs.sp = stackva + sys.pagesize;
        proc.trapframe.epc = entryva;

        proc.state = State.runnable;

        return true;
    }
}
