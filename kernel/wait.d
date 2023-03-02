module kernel.wait;

import kernel.proc;
import kernel.spinlock;

import ulib.list;

struct WaitQueue {
    List!(Proc) procs;
    shared Spinlock lock;

    // Put a process in the wait queue.
    void enqueue(Proc* p) shared {
        lock.lock();
        (cast()this).enqueue_(p);
        lock.unlock();
    }

    void enqueue_(Proc* p) {
        procs.push_back(p.node);
    }

    // Remove a process from the wait queue.
    void remove(Proc* p) shared {
        lock.lock();
        (cast()this).remove_(p);
        lock.unlock();
    }

    void remove_(Proc* p) {
        procs.remove(p.node);
    }

    // Remove all processes from the wait queue and call 'wake' on them.
    void wake_all() shared {
        lock.lock();
        (cast()this).wake_all_();
        lock.unlock();
    }

    void wake_all_() {
        while (procs.length > 0) {
            Proc* p = &procs.front.val;
            p.lock.lock();
            this.wake(p);
            p.lock.unlock();
        }
    }

    // Remove a process from the wait queue and call wake on it.
    void wake_one(Proc* p) shared in (p.lock.holding()) {
        lock.lock();
        (cast()this).wake(p);
        lock.unlock();
    }

    private void wake(Proc* p) in (p.lock.holding())
                               in (p.state == Proc.State.blocked)
                               in (p.wq == &this) {
        import kernel.schedule;
        remove_(p);
        next_runq.enqueue(p);
    }
}
