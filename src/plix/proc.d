module plix.proc;

import plix.alloc : knew, kfree, kzalloc, kalloc;
import plix.arch.vm : Pagetable;
import plix.arch.boot : kernel_procmap;
import plix.arch.regs : Context;
import plix.arch.trap : Trapframe, usertrapret;
import plix.elf : loadelf;
import plix.vm : mappg, Perm, PtIter, iska;
import plix.schedule : Queue;
import plix.fs.file : Inode, File;

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
    enum stack_va = 0x7fff0000;
    // Size of a user stack.
    enum stack_size = sys.pagesize;
    // Maximum virtual address that a user process can access.
    enum max_va = stack_va + stack_size;
    // Stack canary.
    enum canary_magic = 0xfeedface;
    // Max number of open files per process.
    enum nofile = 16;

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

    File*[nofile] ofile;
    Inode* cwd;

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
        p.canary = canary_magic;

        return p;
    }

    static Proc* make_from_parent(Proc* parent) {
        Proc* p = Proc.make_empty();
        if (!p)
            return null;

        foreach (ref map; PtIter.get(parent.pt)) {
            if (!map.user) {
                continue;
            }
            map.pte.perm = (map.perm & ~Perm.w) | Perm.cow;
            if (!p.pt.mappg(map.va, map.pa, Perm.urx | Perm.cow)) {
                kfree(p);
                return null;
            }
        }

        p.parent = parent;
        p.trapframe = parent.trapframe;

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
        ubyte[] ustack = kzalloc(Proc.stack_size);
        if (!ustack) {
            kfree(p);
            return null;
        }
        if (!p.pt.mappg(Proc.stack_va, ustack.ptr, Perm.urw)) {
            kfree(p);
            return null;
        }

        p.trapframe.regs.sp = Proc.stack_va + sys.pagesize - 16;
        p.trapframe.epc = entry;

        return p;
    }

    ~this() {
        import plix.print : printf;
        import plix.page : pages;
        printf("%d: destroyed\n", pid);
        foreach (ref map; PtIter.get(pt)) {
            if (!iska(map.va)) {
                auto pg = &pages[map.pa / sys.pagesize];
                bool irqs = pg.lock();
                if (pg.refcnt == 0) {
                    kfree(cast(void*) map.ka, sys.pagesize);
                }
                pg.unlock(irqs);
            }
        }
    }

    // Disable opAssign because it would overflow the stack.
    @disable void opAssign(Proc);

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
