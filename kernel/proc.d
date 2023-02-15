module kernel.proc;

import core.sync;

import kernel.arch;
import kernel.alloc;
import kernel.board;
import kernel.spinlock;

import kernel.fs.vfs;
import kernel.fs.console;

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
    enum maxva = stackva + sys.pagesize;

    // Must be the first field in Proc.
    Trapframe trapframe;

    // scheduling list node
    List!(Proc).Node* node;

    int pid = -1;
    Pagetable* pt;
    Proc* parent;
    uint children;

    struct Brk {
        uintptr initial;
        uintptr current;
    }
    Brk brk;

    enum State {
        runnable = 0,
        waiting,
        sleeping,
        exited,
    }
    State state;
    ulong sleep_end;

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
        uintptr brk = elf.load!(64)(proc.pt, binary.ptr, entryva, &alloc);
        if (!brk) {
            alloc.free_checkpoint();
            return false;
        }
        import ulib.math : align_off;
        brk += align_off(brk, sys.pagesize);

        // map kernel
        assert(kernel_map(proc.pt));
        // allocate stack
        void* stack = kalloc_custom(&alloc, sys.pagesize);
        if (!stack) {
            alloc.free_checkpoint();
            return false;
        }
        memset(stack, 0, sys.pagesize);
        // map stack
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) stack), Pte.Pg.normal, Perm.urwx, &alloc)) {
            alloc.free_checkpoint();
            return false;
        }

        if (!proc.init_fdtable(&alloc)) {
            alloc.free_checkpoint();
            return false;
        }

        alloc.done_checkpoint();

        // initialize registers (stack, pc)
        memset(&proc.trapframe.regs, 0, Regs.sizeof);
        proc.trapframe.regs.sp = stackva + sys.pagesize - 16;
        proc.trapframe.epc = entryva;
        proc.children = 0;
        proc.brk.initial = brk;
        proc.brk.current = 0;

        proc.pid = atomic_rmw_add(&nextpid, 1);

        return true;
    }

    FdTable* fdtable;

    bool init_fdtable(A)(A* alloc) {
        fdtable = knew_custom!(FdTable)(alloc);
        if (!fdtable) {
            return false;
        }
        fdtable.files[0] = Console.stdin;
        fdtable.files[1] = Console.stdout;
        fdtable.files[2] = Console.stderr;
        fdtable.refcount = 1;
        return true;
    }
}
