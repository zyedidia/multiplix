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

    uint pid;

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
        const bool ok = elf.load!64(proc, binary.ptr, entryva);
        if (!ok) {
            // TODO: free memory
            return false;
        }
        // map kernel
        assert(kernel_map(proc.pt));
        // allocate stack/trapframe
        auto stack_ = kalloc_block(sys.pagesize * 2);
        if (!stack_.get()) {
            kfree(proc.pt);
            kfree(proc.code.ptr);
            return false;
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

        sync_idmem(proc.code.ptr, proc.code.length);

        return true;
    }
}

struct ProcTable(uint size) {
    Proc[size] procs;
    Sched[size] sched;

    shared Spinlock lock;

    struct Sched {
        ulong priority;
    }

    private Opt!(Proc*) next() {
        for (uint i = 0; i < size; i++) {
            if (procs[i].state == Proc.State.free) {
                procs[i].pid = i;
                return Opt!(Proc*)(&procs[i]);
            }
        }
        return Opt!(Proc*).none;
    }

    bool start(immutable ubyte[] binary) {
        lock.lock();
        scope(exit) lock.unlock();

        auto p_ = next();
        if (!p_.has()) {
            return false;
        }
        return Proc.make(p_.get(), binary);
    }

    void free(uint pid) {
        lock.lock();
        scope(exit) lock.unlock();

        procs[pid].state = Proc.State.free;
    }

    Proc* schedule() {
        uint imin = 0;
        {
            lock.lock();
            scope(exit) lock.unlock();

            ulong min = ulong.max;
            for (uint i = 0; i < size; i++) {
                if (sched[i].priority <= min && procs[i].state == Proc.State.runnable) {
                    imin = i;
                }
            }
            sched[imin].priority++;
        }

        return &procs[imin];
    }
}
