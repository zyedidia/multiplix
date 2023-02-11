module kernel.proc;

import core.sync;

import kernel.arch;
import kernel.alloc;
import kernel.board;
import kernel.spinlock;

import sys = kernel.sys;
import vm = kernel.vm;
import elf = kernel.elf;

import ulib.list;
import ulib.option;
import ulib.memory;
import ulib.vector;

shared int nextpid = 0;

struct Proc {
    enum stackva = 0x7fff0000;

    Trapframe trapframe;

    // scheduling list node
    List!(Proc).Node* node;

    int pid = -1;
    Pagetable* pt;
    Proc* parent;

    enum State {
        runnable = 0,
        waiting,
        exited,
    }

    State state;

    static bool make(Proc* proc, immutable ubyte[] binary) {
        // Checkpoint so we can free all memory if there is a failure.
        auto alloc = CheckpointAllocator!(typeof(sys.allocator))(&sys.allocator);

        alloc.checkpoint();
        // allocate pagetable
        Pagetable* pt = knew_custom!(Pagetable)(&alloc);
        if (!pt) {
            alloc.free_checkpoint();
            return false;
        }
        proc.pt = pt;
        uintptr entryva;
        const bool ok = elf.load!(64)(proc.pt, binary.ptr, entryva, &alloc);
        if (!ok) {
            alloc.free_checkpoint();
            return false;
        }
        // map kernel
        assert(kernel_map(proc.pt));
        // allocate stack
        void* stack = kalloc_custom(&alloc, sys.pagesize);
        if (!stack) {
            alloc.free_checkpoint();
            return false;
        }
        // map stack
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) stack), Pte.Pg.normal, Perm.urwx, &alloc)) {
            alloc.free_checkpoint();
            return false;
        }
        alloc.done_checkpoint();

        // initialize registers (stack, pc)
        memset(&proc.trapframe.regs, 0, Regs.sizeof);
        proc.trapframe.regs.sp = stackva + sys.pagesize;
        proc.trapframe.epc = entryva;

        proc.pid = atomic_rmw_add(&nextpid, 1);

        return true;
    }
}
