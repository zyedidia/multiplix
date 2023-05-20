module plix.proc;

import plix.alloc : knew, kfree, kzalloc;
import plix.arch.vm : Pagetable;
import plix.arch.boot : kernel_procmap;
import plix.arch.regs : Context;
import plix.arch.trap : Trapframe, usertrapret;
import plix.elf : loadelf;
import plix.vm : mappg, Perm;
import plix.schedule : Queue;

import sys = plix.sys;

enum ProcState {
    runnable = 0,
    blocked,
    exited,
}

// TODO: synchronization
__gshared int next_pid;

struct Proc {
    // Virtual address of the user stack.
    enum STACK_VA = 0x7fff0000;
    // Size of a user stack.
    enum STACK_SIZE = sys.pagesize;
    // Maximum virtual address that a user process can access.
    enum MAX_VA = STACK_VA + STACK_SIZE;
    // Stack canary.
    enum CANARY = 0xfeedface_deadbeef;

    Trapframe trapframe;

    Context context;

    int pid;
    Pagetable* pt;
    Proc* parent;
    uint children;

    ProcState state;
    void* wq;

    Proc* next;
    Proc* prev;

    uint canary;
    align(16) ubyte[3008] kstack;
    static assert(kstack.length % 16 == 0);

    static Proc* make_empty() {
        Pagetable* pgtbl = knew!(Pagetable)();
        if (!pgtbl)
            return null;
        kernel_procmap(pgtbl);

        Proc* p = knew!(Proc)();
        if (!p) {
            pgtbl.free();
            kfree(pgtbl);
            return null;
        }

        p.pid = next_pid++;
        p.pt = pgtbl;
        p.context = Context(p.kstackp(), cast(uintptr) &Proc.forkret, pgtbl);

        return p;
    }

    static Proc* make_from_elf(ubyte[] bin) {
        Proc* p = Proc.make_empty();
        if (!p)
            return null;

        uintptr entry, brk;
        if (!loadelf(p.pt, bin.ptr, entry, brk)) {
            kfree(p);
            return null;
        }

        // Allocate/map stack
        ubyte[] ustack = kzalloc(Proc.STACK_SIZE);
        if (!ustack) {
            kfree(p);
            return null;
        }
        if (!p.pt.mappg(Proc.STACK_VA, ustack.ptr, Perm.urw)) {
            kfree(p);
            return null;
        }

        p.trapframe.regs.sp = Proc.STACK_VA + sys.pagesize - 16;
        p.trapframe.epc = entry;

        return p;
    }

    ~this() {
        // TODO
    }

    // Returns the top of the kernel stack.
    uintptr kstackp() {
        return cast(uintptr) &kstack[$-16];
    }

    void yield() {
        import plix.arch.trap : Irq;
        import plix.schedule : scheduler, kswitch;

        assert(!Irq.enabled());
        kswitch(null, &this.context, &scheduler);
    }

    void block(Queue* queue) {
        wait(queue, ProcState.blocked);
    }

    void exit(Queue* queue) {
        wait(queue, ProcState.exited);
    }

    void wait(Queue* queue, ProcState state) {
        this.state = state;
        this.wq = cast(void*) queue;
        queue.push_front(&this);
    }

    void unblock() {
        wq = null;
    }

    static void forkret(Proc* p) {
        usertrapret(p);
    }
}
