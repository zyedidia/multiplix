module kernel.schedule;

import kernel.spinlock;
import kernel.proc;
import kernel.arch;
import ulib.list;

struct RunQ {
    Proc* curproc;
    List!(Proc) runnable;

    shared Spinlock lock;

    Context context;

    alias Node = List!(Proc).Node;

    size_t length() {
        lock.lock();
        scope(exit) lock.unlock();
        return runnable.length;
    }

    Proc* next() {
        Node* n = knew!(Node)();
        if (!n) {
            return null;
        }
        import ulib.alloc;
        emplace_init(&n.val);

        Proc* p = &n.val;
        p.node = n;
        return p;
    }

    import kernel.alloc;
    bool start(ubyte[] binary) {
        Proc* p = next();
        if (!p) {
            return false;
        }
        if (!p.initialize(binary)) {
            kfree(p.node);
            return false;
        }
        enqueue(p);
        return true;
    }

    // Puts n in the runnable queue.
    void enqueue(Proc* p) {
        p.state = Proc.State.runnable;
        lock.lock();
        runnable.push_back(p.node);
        lock.unlock();
    }

    // Returns the next process to run, or null if there are no runnable processes.
    Proc* schedule() {
        lock.lock();
        scope(exit) lock.unlock();
        if (runnable.length == 0) {
            return null;
        }
        Node* n = runnable.pop_front();
        return &n.val;
    }
}

import kernel.board;
__gshared RunQ[Machine.ncores] global_runqs;

import kernel.cpu;
ref RunQ runq() {
    return global_runqs[cpu.coreid];
}

ref RunQ next_runq() {
    import ulib.rand;
    int core = rand() % Machine.ncores;
    println("next core ", core);
    return global_runqs[core];
    // return global_runqs[1];
}

extern (C) void kswitch(Context* oldp, Context* newp);

noreturn scheduler() {
    import kernel.irq;

    while (1) {
        // Allow devices to interrupt in case all processes are sleeping.
        Irq.on();

        Proc* p = null;
        while (!p) {
            p = runq.schedule();
            // wait in low power state if there are no processes
            if (!p)
                wfi();
            println(cpu.coreid, " ", p);
        }
        Irq.off();
        assert(p.state == Proc.State.runnable);
        runq.curproc = p;
        kswitch(&runq.context, &p.context);

        // process is done running for now
        runq.curproc = null;
        if (p.state == Proc.State.runnable) {
            runq.enqueue(p);
        }
    }
}
