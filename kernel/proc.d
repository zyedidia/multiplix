module kernel.proc;

import kernel.spinlock;
import kernel.arch;
import sys = kernel.sys;
import ulib.list;

shared int nextpid = 0;

struct Proc {
    // Must be the first field in Proc.
    Trapframe trapframe;

    enum stackva = 0x7fff0000;
    enum maxva = stackva + sys.pagesize;

    // Context for kernel switches.
    Context context;

    // Scheduling node.
    List!(Proc).Node* node;

    shared Spinlock lock;

    int pid = -1;
    Pagetable* pt;
    Proc* parent;
    uint children;
    void* ustack;

    struct Brk {
        uintptr initial;
        uintptr current;
    }
    Brk brk;

    enum State {
        runnable = 0,
        blocked,
        exited,
    }

    State state;

    enum magic = 0xdeadbeef;
    uint canary = magic;

    // The proc struct contains the entire kernel stack. Do not create Proc
    // structs on the stack.
    align(16) ubyte[2000] kstack;
    static assert(kstack.length % 16 == 0);

    import kernel.vm;

    bool initialize(immutable ubyte[] code) {
        import kernel.alloc;
        import elf = kernel.elf;
        import ulib.math;
        import ulib.memory;

        auto alloc = CkptAllocator!(typeof(sys.allocator))(&sys.allocator);
        alloc.ckpt();

        pt = knew_custom!(Pagetable)(&alloc);
        if (!pt) {
            alloc.free_ckpt();
            return false;
        }
        uintptr entryva, brk;
        if (!elf.load!(64)(pt, code.ptr, entryva, brk, &alloc)) {
            alloc.free_ckpt();
            return false;
        }
        brk += align_off(brk, sys.pagesize);

        // map kernel
        kernel_procmap(pt);
        // allocate stack
        ustack = kalloc_custom(&alloc, sys.pagesize);
        if (!ustack) {
            alloc.free_ckpt();
            return false;
        }
        memset(ustack, 0, sys.pagesize);
        // map stack
        if (!pt.map(stackva, ka2pa(cast(uintptr) ustack), Pte.Pg.normal, Perm.urw, &alloc)) {
            alloc.free_ckpt();
            return false;
        }

        alloc.done_ckpt();

        // initialize registers and user process information
        memset(&trapframe.regs, 0, Regs.sizeof);
        trapframe.regs.sp = stackva + sys.pagesize - 16;
        trapframe.epc = entryva;
        children = 0;
        this.brk.initial = brk;
        this.brk.current = 0;
        import core.sync;
        pid = atomic_rmw_add(&nextpid, 1);

        // initialize kernel context
        context.sp = kstackp();
        context.retaddr = cast(uintptr) &forkret;

        return true;
    }

    uintptr kstackp() {
        return cast(uintptr) &kstack[$-1];
    }

    void free() {
        unmappg(pt, stackva, Pte.Pg.normal, true);
        pt.free();
    }

    void yield() {
        import kernel.schedule;
        import kernel.irq;
        assert(!Irq.is_on());
        assert(canary == Proc.magic);

        bool irqen = Irq.irqen;
        kswitch(&context, &runq.context);
        Irq.irqen = irqen;
    }

    static void forkret() {
        import kernel.schedule;
        usertrapret(runq.curproc);
    }
}
