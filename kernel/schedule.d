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
    Vector!(Proc) waiting;

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

    bool wait(size_t slot) {
        return move!(waiting, runnable)(slot);
    }

    bool done_wait(size_t slot) {
        return move!(runnable, waiting)(slot);
    }

    void exit(size_t slot) {
        cast(void) remove!(runnable)(slot);
    }

    // Moves the process in from[slot] into to.
    bool move(alias Vector!(Proc) to, alias Vector!(Proc) from)(size_t slot) {
        return append!(to)(remove!(from)(slot));
    }

    // Appends p to vec.
    private bool append(alias Vector!(Proc) vec)(Proc p) {
        if (!vec.append(p)) {
            return false;
        }
        vec[vec.length - 1].slot = vec.length - 1;
        vec[vec.length - 1].update_trapframe();
        return true;
    }

    // Removes vec[slot].
    Proc remove(alias Vector!(Proc) vec)(size_t slot) {
        auto p = vec[slot];
        vec[slot] = vec[vec.length - 1];
        vec[slot].slot = slot;
        vec[slot].update_trapframe();
        vec.length--;
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
