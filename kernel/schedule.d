module kernel.schedule;

import kernel.proc;
import kernel.arch;
import ulib.list;

struct RunQ {
    Proc* curproc;
    List!(Proc) runnable;
    List!(Proc) blocked;
    List!(Proc) exited;

    Context context;

    alias Node = List!(Proc).Node;

    size_t length() {
        return runnable.length;
    }

    Proc* next() {
        auto n = runnable.push_back(Proc());
        if (!n) {
            return null;
        }
        Proc* p = &n.val;
        p.node = n;
        return p;
    }

    import kernel.alloc;
    bool start(immutable ubyte[] binary) {
        Proc* p = next();
        if (!p) {
            return false;
        }
        if (!p.initialize(binary)) {
            kfree(runnable.pop_back());
            return false;
        }
        return true;
    }

    void block(Node* n) {
        n.val.state = Proc.State.blocked;
        move!(blocked, runnable)(n);
    }

    void unblock(Node* n) {
        n.val.state = Proc.State.runnable;
        move!(runnable, blocked)(n);
    }

    void exit(Node* n) {
        n.val.state = Proc.State.exited;
        move!(exited, runnable)(n);
    }

    // Moves the process from one queue to another.
    private void move(alias List!(Proc) to, alias List!(Proc) from)(Node* n) {
        from.remove(n);
        to.push_back(n);
    }

    // Returns the next process to run, or null if there are no runnable processes.
    Proc* schedule() {
        if (runnable.length == 0) {
            return null;
        }
        Node* n = runnable.pop_front();
        runnable.push_back(n);
        return &n.val;
    }
}

RunQ runq;

extern (C) void kswitch(Context* oldp, Context* newp);

noreturn scheduler() {
    import kernel.irq;

    while (1) {
        // Allow devices to interrupt in case all processes are sleeping.
        Irq.on();

        Proc* p = null;
        while (!p) {
            p = runq.schedule();
            // TODO: wait in low power state if there are no processes
        }
        assert(p.state == Proc.State.runnable);
        runq.curproc = p;
        kswitch(&runq.context, &p.context);

        // process is done running for now
        runq.curproc = null;
    }
}
