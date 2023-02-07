module kernel.proc;

import core.sync;

import kernel.arch;
import kernel.alloc;
import kernel.board;
import kernel.spinlock;

import sys = kernel.sys;
import vm = kernel.vm;
import elf = kernel.elf;

import ulib.option;
import ulib.memory;
import ulib.vector;

shared int nextpid = 0;

struct Proc {
    enum stackva = 0x7fff0000;
    enum trapframeva = stackva - sys.pagesize;

    Trapframe* trapframe;

    int pid = -1;
    size_t slot;
    Pagetable* pt;
    Vector!(int) waiters;

    static bool make(Proc* proc, immutable ubyte[] binary) {
        // Checkpoint so we can free all memory if there is a failure.
        System.allocator.checkpoint();
        // allocate pagetable
        Pagetable* pt = knew!(Pagetable)();
        if (!pt) {
            System.allocator.free_checkpoint();
            return false;
        }
        proc.pt = pt;
        uintptr entryva;
        const bool ok = elf.load!64(proc.pt, binary.ptr, entryva);
        if (!ok) {
            System.allocator.free_checkpoint();
            return false;
        }
        // map kernel
        assert(kernel_map(proc.pt));
        // allocate stack/trapframe
        void* stack = kalloc(sys.pagesize);
        if (!stack) {
            System.allocator.free_checkpoint();
            return false;
        }
        void* trapframe = kalloc(sys.pagesize);
        if (!trapframe) {
            System.allocator.free_checkpoint();
            return false;
        }
        proc.trapframe = cast(Trapframe*) trapframe;
        // map stack/trapframe
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) stack), Pte.Pg.normal, Perm.urwx, &System.allocator)) {
            System.allocator.free_checkpoint();
            return false;
        }
        if (!proc.pt.map(trapframeva, vm.ka2pa(cast(uintptr) proc.trapframe), Pte.Pg.normal, Perm.krwx, &System.allocator)) {
            System.allocator.free_checkpoint();
            return false;
        }
        System.allocator.done_checkpoint();

        // initialize registers (stack, pc)
        memset(&proc.trapframe.regs, 0, Regs.sizeof);
        proc.trapframe.regs.sp = stackva + sys.pagesize;
        proc.trapframe.epc = entryva;
        proc.update_trapframe();

        proc.pid = atomic_rmw_add(&nextpid, 1);

        return true;
    }

    void update_trapframe() {
        this.trapframe.p = &this;
    }
}
