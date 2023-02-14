module kernel.schedule;

import kernel.proc;
import kernel.spinlock;
import kernel.board;
import kernel.cpu;

import arch = kernel.arch;

import ulib.option;
import ulib.list;
import rand = ulib.rand;

import io = ulib.io;

struct RunQ {
    uint runpid = -1;
    List!(Proc) runnable;
    List!(Proc) waiting;
    List!(Proc) sleeping;
    List!(Proc) exited;

    alias ProcNode = List!(Proc).Node;

    size_t length() {
        return runnable.length;
    }

    Opt!(Proc*) next() {
        auto n = runnable.push_back(Proc());
        if (!n) {
            return Opt!(Proc*).none;
        }
        Proc* p = &n.val;
        p.node = n;
        return Opt!(Proc*)(p);
    }

    bool start(immutable ubyte[] binary) {
        auto p_ = next();
        if (!p_.has()) {
            return false;
        }
        return Proc.make(p_.get(), binary);
    }

    void wait(ProcNode* n) {
        n.val.state = Proc.State.waiting;
        move!(waiting, runnable)(n);
    }

    void done_wait(ProcNode* n) {
        n.val.state = Proc.State.runnable;
        move!(runnable, waiting)(n);
    }

    void exit(ProcNode* n) {
        n.val.state = Proc.State.exited;
        move!(exited, runnable)(n);
    }

    void sleep(ProcNode* n, ulong end_time) {
        n.val.state = Proc.State.sleeping;
        n.val.sleep_end = end_time;
        move!(sleeping, runnable)(n);
        assert(sleeping.length > 0);
    }

    void wakeup_sleepers() {
        ulong now = arch.Timer.ns();
        foreach (ProcNode *n; sleeping) {
            if (n.val.sleep_end <= now) {
                n.val.state = Proc.State.runnable;
                move!(runnable, sleeping)(n);
            }
        }
    }

    // Moves the process in from[slot] into to.
    private void move(alias List!(Proc) to, alias List!(Proc) from)(ProcNode* n) {
        from.remove(n);
        to.push_back(n);
    }

    // Returns the next process to run, or none if there are no runnable processes.
    Opt!(Proc*) schedule() {
        wakeup_sleepers();
        if (runnable.length == 0) {
            return Opt!(Proc*).none;
        }
        ProcNode* n = runnable.pop_front();
        runnable.push_back(n);
        return Opt!(Proc*)(&n.val);
    }
}

struct GlobalRunQ {
    shared RunQ[Machine.ncores] queues;

    RunQ* queue() shared return {
        return cast(RunQ*) &queues[cpuinfo.coreid];
    }

    alias queue this;
}

shared GlobalRunQ runq;

noreturn schedule() {
    Opt!(Proc*) p;
    while (!p.has()) {
        p = runq.schedule();
    }

    if (runq.runpid != -1 && runq.runpid == p.get().pid) {
        // continue running the same process
        arch.usertrapret(p.get(), false);
    } else {
        runq.runpid = p.get().pid;
        arch.usertrapret(p.get(), true);
    }
}
