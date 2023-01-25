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

struct Proc {
    enum stackva = 0x7fff0000;
    enum trapframeva = stackva - sys.pagesize;

    enum State {
        free = 0,
        runnable,
        running,
    }

    Trapframe* trapframe;

    // protects the following fields (not trapframe)
    private shared Spinlock _lock;

    uint pid;
    Pagetable* pt;
    State state;
    ubyte[] code;
    ubyte[] stack;

    void lock() {
        this._lock.lock();
    }

    void unlock() {
        this._lock.unlock();
    }

    static bool make(Proc* proc, immutable ubyte[] binary) {
        // Checkpoint so we can free all memory if there is a failure.
        System.allocator.checkpoint();
        // allocate pagetable
        auto pt_ = kalloc!(Pagetable)();
        if (!pt_.has()) {
            System.allocator.free_checkpoint();
            return false;
        }
        proc.pt = pt_.get();
        // allocate physical space for binary, and copy it in
        auto pgs_ = kalloc_block(binary.length);
        if (!pgs_.get()) {
            System.allocator.free_checkpoint();
            return false;
        }
        uintptr entryva;
        const bool ok = elf.load!64(proc, binary.ptr, entryva);
        if (!ok) {
            System.allocator.free_checkpoint();
            return false;
        }
        // map kernel
        assert(kernel_map(proc.pt));
        // allocate stack/trapframe
        auto stack_ = kalloc_block(sys.pagesize * 2);
        if (!stack_.get()) {
            System.allocator.free_checkpoint();
            return false;
        }
        proc.stack = cast(ubyte[]) stack_.get()[0 .. sys.pagesize];
        proc.trapframe = cast(Trapframe*) stack_.get()[sys.pagesize .. sys.pagesize * 2];
        // map stack/trapframe
        if (!proc.pt.map(stackva, vm.ka2pa(cast(uintptr) proc.stack.ptr), Pte.Pg.normal, Perm.urwx, &System.allocator)) {
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
        proc.trapframe.p = proc;

        proc.state = State.runnable;

        sync_idmem(proc.code.ptr, proc.code.length);

        return true;
    }
}
