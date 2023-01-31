module kernel.schedule;

import kernel.proc;
import kernel.spinlock;
import kernel.board;
import kernel.cpu;

import arch = kernel.arch;

import ulib.option;
import ulib.vector;
import rand = ulib.rand;

import io = ulib.io;

struct RunQ {
    uint runpid = -1;
    Vector!(Proc) runnable;
    Vector!(Proc) blocked;

    size_t length() {
        return runnable.length;
    }

    Opt!(Proc*) next() {
        if (!runnable.append(Proc())) {
            return Opt!(Proc*).none;
        }
        Proc* p = &runnable[runnable.length - 1];
        p.slot = runnable.length - 1;
        return Opt!(Proc*)(&runnable[runnable.length - 1]);
    }

    bool start(immutable ubyte[] binary) {
        auto p_ = next();
        if (!p_.has()) {
            return false;
        }
        return Proc.make(p_.get(), binary);
    }

    void unblock(size_t slot) {
        auto p = remove_blocked(slot);
        runnable.append(p);
        runnable[runnable.length - 1].slot = runnable.length - 1;
        runnable[runnable.length - 1].update_trapframe();
    }

    void block(size_t slot) {
        auto p = remove_runnable(slot);
        blocked.append(p);
        blocked[blocked.length - 1].slot = blocked.length - 1;
        blocked[blocked.length - 1].update_trapframe();
    }

    void exit(size_t slot) {
        remove_runnable(slot);
    }

    private Proc remove_blocked(size_t slot) {
        auto p = blocked[slot];
        blocked[slot] = blocked[blocked.length - 1];
        blocked[slot].slot = slot;
        blocked[slot].update_trapframe();
        blocked.length--;
        return p;
    }

    private Proc remove_runnable(size_t slot) {
        auto p = runnable[slot];
        runnable[slot] = runnable[runnable.length - 1];
        runnable[slot].slot = slot;
        runnable[slot].update_trapframe();
        runnable.length--;
        return p;
    }

    // Returns the next process to run, or none if there are no runnable processes.
    Opt!(Proc*) schedule() {
        if (runnable.length <= 0) {
            return Opt!(Proc*).none;
        }
        uint choice = rand.gen_uint() % runnable.length;
        return Opt!(Proc*)(&runnable[choice]);
    }
}

struct GlobalRunQ {
    shared RunQ[System.ncores] queues;

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
