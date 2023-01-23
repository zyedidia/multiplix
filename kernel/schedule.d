module kernel.schedule;

import kernel.proc;
import kernel.spinlock;

import arch = kernel.arch;

import ulib.option;

import io = ulib.io;

__gshared ProcTable!(10) ptable;
Proc* curproc;

struct ProcTable(uint size) {
    Proc[size] procs;
    Sched[size] sched;

    shared Spinlock lock;

    struct Sched {
        ulong priority;
    }

    private Opt!(Proc*) next() {
        for (uint i = 0; i < size; i++) {
            if (procs[i].state == Proc.State.free) {
                procs[i].pid = i;
                return Opt!(Proc*)(&procs[i]);
            }
        }
        return Opt!(Proc*).none;
    }

    bool start(immutable ubyte[] binary) {
        lock.lock();
        scope(exit) lock.unlock();

        auto p_ = next();
        if (!p_.has()) {
            return false;
        }
        return Proc.make(p_.get(), binary);
    }

    void free(uint pid) {
        lock.lock();
        scope(exit) lock.unlock();

        procs[pid].state = Proc.State.free;
    }

    Proc* schedule() {
        uint imin = 0;
        {
            lock.lock();
            scope(exit) lock.unlock();

            ulong min = ulong.max;
            for (uint i = 0; i < size; i++) {
                if (sched[i].priority <= min && procs[i].state == Proc.State.runnable) {
                    imin = i;
                    min = sched[i].priority;
                }
            }
            sched[imin].priority++;
        }

        return &procs[imin];
    }
}

noreturn schedule() {
    auto p = ptable.schedule();
    if (curproc == p) {
        arch.usertrapret(p, false);
    } else {
        curproc = p;
        arch.usertrapret(p, true);
    }
}
