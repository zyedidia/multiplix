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
    import kernel.alloc;

    bool initialize(ubyte[] bin) {
        import elf = kernel.elf;
        import ulib.math;
        import ulib.memory;

        pt = knew!(Pagetable)();
        if (!pt) {
            return false;
        }
        uintptr entryva, brk;
        if (!elf.load!(64)(pt, bin.ptr, entryva, brk)) {
            free();
            return false;
        }
        brk += align_off(brk, sys.pagesize);

        // map kernel
        kernel_procmap(pt);
        // allocate stack
        ustack = kalloc(sys.pagesize);
        if (!ustack) {
            free();
            return false;
        }
        memset(ustack, 0, sys.pagesize);
        // map stack
        if (!pt.mappg(stackva, ka2pa(cast(uintptr) ustack), Perm.urw)) {
            free();
            return false;
        }

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
        return cast(uintptr) &kstack[$-16];
    }

    void free() {
        foreach (map; VmRange(pt)) {
            if (!iska(map.va)) {
                import kernel.page;
                pages[map.pa / sys.pagesize].refcount--;
                if (pages[map.pa / sys.pagesize].refcount == 0)
                    kfree(cast(void*) map.ka);
            }
        }

        pt.free();
    }

    // Switch to another kernel thread.
    void yield() {
        import kernel.schedule;
        import kernel.irq;
        assert(!Irq.is_on());
        assert(canary == Proc.magic);

        bool irqen = Irq.irqen;
        kswitch(&context, &runq.context);

        .brk();
        asm {
            "" ::: "tp";
        }

        // NOTE: we may resume on a different core if a migration has occurred.
        // This means if we access thread-local storage (which we do), we have
        // to be careful. On certain architectures (aarch64) the thread-pointer
        // is a system register, which the compiler does not assume to be
        // clobbered by a function call (in fact, I don't think it is possible
        // to directly express that the thread pointer has been clobbered).
        // Thus we have to clobber the entire register file.
        Irq.irqen = irqen;
    }

    import kernel.wait;
    import kernel.schedule;

    // Removes this proc from the runnable queue, yields, and places it
    // back.
    void block() {
        state = Proc.State.blocked;
        yield();
    }

    static void forkret() {
        usertrapret(runq.curproc);
    }
}
