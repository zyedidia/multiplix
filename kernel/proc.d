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

    bool initialize(immutable ubyte[] bin) {
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
        if (!pt.map(stackva, ka2pa(cast(uintptr) ustack), Pte.Pg.normal, Perm.urw, &sys.allocator)) {
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
            // only free writable pages because those are the only pages that
            // are owned by the process (copy-on-write).
            if (map.va < sys.highmem_base && map.write()) {
                kfree(cast(void*) pa2ka(map.pa));
            }
        }

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
