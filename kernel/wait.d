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
        (cast()procs).push_back(p.node);
        lock.unlock();
    }

    // Remove a process from the wait queue.
    void remove(Proc* p) shared {
        lock.lock();
        (cast()procs).remove(p.node);
        lock.unlock();
    }

    // Remove all processes from the wait queue and call 'wake' on them.
    void wake_all() shared {
        lock.lock();
        while ((cast()procs).length > 0) {
            (cast()this).wake(&(cast()procs).front.val);
        }
        lock.unlock();
    }

    // Remove a process from the wait queue and call wake on it.
    void wake_one(Proc* p) shared {
        lock.lock();
        (cast()this).wake(p);
        lock.unlock();
    }

    private void wake(Proc* p) {
        import kernel.schedule;
        (cast()procs).remove(p.node);
        runq.enqueue(p);
    }
}
