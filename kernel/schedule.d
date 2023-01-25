module kernel.schedule;

import kernel.proc;
import kernel.spinlock;

import arch = kernel.arch;

import ulib.option;

import io = ulib.io;

__gshared ProcTable!(10) ptable;
Opt!(Proc*) curproc;

struct ProcTable(uint size) {
    Proc[size] procs;
    Sched[size] sched;

    // protects sched
    shared Spinlock sched_lock;

    struct Sched {
        ulong priority;
    }

    size_t length() {
        size_t len = 0;
        foreach (p; procs) {
            p.lock();
            len += p.state != Proc.State.free;
            p.unlock();
        }
        return len;
    }

    private Opt!(Proc*) next() {
        for (uint i = 0; i < size; i++) {
            procs[i].lock();
            scope(exit) procs[i].unlock();
            if (procs[i].state == Proc.State.free) {
                procs[i].pid = i;
                return Opt!(Proc*)(&procs[i]);
            }
        }
        return Opt!(Proc*).none;
    }

    bool start(immutable ubyte[] binary) {
        auto p_ = next();
        if (!p_.has()) {
            return false;
        }
        auto p = p_.get();
        p.lock();
        scope(exit) p.unlock();
        return Proc.make(p_.get(), binary);
    }

    void free(uint pid) {
        procs[pid].lock();
        scope(exit) procs[pid].unlock();

        procs[pid].state = Proc.State.free;
    }

    Opt!(Proc*) schedule() {
        sched_lock.lock();
        scope(exit) sched_lock.unlock();

        ulong min = ulong.max;
        Opt!uint imin = Opt!uint(0);
        for (uint i = 0; i < size; i++) {
            procs[i].lock();
            scope(exit) procs[i].unlock();
            if (sched[i].priority <= min && procs[i].state == Proc.State.runnable) {
                imin = Opt!uint(i);
                min = sched[i].priority;
            }
        }

        if (!imin.has()) {
            return Opt!(Proc*).none;
        }

        sched[imin.get()].priority++;
        return Opt!(Proc*)(&procs[imin.get()]);
    }
}

noreturn schedule() {
    Opt!(Proc*) p_;
    while (!p_.has()) {
        p_ = ptable.schedule();
    }
    auto p = p_.get();

    if (curproc.has() && curproc.get() == p) {
        arch.usertrapret(p, false);
    } else {
        ptable.sched_lock.lock();
        if (curproc.has()) {
            curproc.get().lock();
            curproc.get().state = Proc.State.runnable;
            curproc.get().unlock();
        }

        p.lock();
        p.state = Proc.State.running;
        p.unlock();

        curproc = Opt!(Proc*)(p);
        ptable.sched_lock.unlock();
        arch.usertrapret(p, true);
    }
}
