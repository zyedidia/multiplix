module kernel.proc;

import core.sync;

import kernel.arch;
import kernel.alloc;
import kernel.board;

import sys = kernel.sys;
import vm = kernel.vm;
import elf = kernel.elf;

import ulib.memory;

struct Proc {
    enum stackva = 0x7fff0000;
    enum trapframeva = stackva - sys.pagesize;

    enum State {
        runnable,
        running,
    }

    int pid;

    Trapframe* trapframe;

    Pagetable* pt;
    State state;
    ubyte[] code;
    ubyte[] stack;

    static bool make(Proc* proc, immutable ubyte[] binary) {
        // TODO: use arena allocation to ease memory cleanup
        // allocate pagetable
        auto pt_ = kalloc!(Pagetable)();
        if (!pt_.has()) {
            return false;
        }
        proc.pt = pt_.get();
        // allocate physical space for binary, and copy it in
        auto pgs_ = kalloc_block(binary.length);
        if (!pgs_.get()) {
            kfree(proc.pt);
            return false;
        }
        uintptr entryva;
        bool failed = elf.load!64(proc, binary.ptr, entryva);
        // map kernel
        for (uintptr pa = 0; pa < System.mem.start + System.mem.sz; pa += sys.gb!(1)) {
            proc.pt.map_giga(vm.pa2ka(pa), pa, Perm.krwx);
        }
        // allocate stack/trapframe
        auto stack_ = kalloc_block(sys.pagesize * 2);
        if (!stack_.get()) {
            kfree(proc.pt);
            kfree(proc.code.ptr);
        }
        proc.stack = cast(ubyte[]) stack_.get()[0 .. sys.pagesize];
        proc.trapframe = cast(Trapframe*) stack_.get()[sys.pagesize .. sys.pagesize * 2];
        // map stack/trapframe
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) proc.stack.ptr), Pte.Pg.normal, Perm.urwx, &System.allocator)) {
            // TODO: if failed, free memory
            return false;
        }
        if (!proc.pt.map(trapframeva, vm.ka2pa(cast(uintptr) proc.trapframe), Pte.Pg.normal, Perm.krwx, &System.allocator)) {
            // TODO: if failed, free memory
            return false;
        }
        // initialize registers (stack, pc)
        memset(&proc.trapframe.regs, 0, Regs.sizeof);
        proc.trapframe.regs.sp = stackva + sys.pagesize;
        proc.trapframe.epc = entryva;
        proc.trapframe.p = proc;

        proc.state = State.runnable;
        proc.pid = 42;

        insn_fence();

        return true;
    }

    int getpid() {
        return pid;
    }

    void putc(char c) {
        import io = ulib.io;
        io.write(c);
    }
}
