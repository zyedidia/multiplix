module kernel.spinlock;
import ulib.print;

import core.sync;

import kernel.cpu;
import kernel.irq;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked = 0;
    Cpu* mycpu = null; // used to determine if this core is holding the lock

    // Acquire the lock.
    shared void lock() {
        mixin(DisableCheck!());
        Irq.push_off(); // disable interrupts to avoid deadlock
        assert(!holding());

        import kernel.board;
        while (lock_test_and_set(&locked, 1) != 0) {
        }
        memory_fence();
        (cast() this).mycpu = &cpu();
    }

    // Release the lock.
    shared void unlock() in (holding()) {
        mixin(DisableCheck!());
        (cast() this).mycpu = null;
        memory_fence();
        lock_release(&locked);

        Irq.pop_off();
    }

    shared bool holding() {
        mixin(DisableCheck!());
        // TODO: fix data race here
        return atomic_load(&locked) && cast(void*) mycpu == cast(void*) &cpu();
    }
}

struct Protected(T) {
    private T val;
    private shared Spinlock lock_;

    void use(void function(ref T) fn) shared {
        lock_.lock();
        fn(cast(T) val);
        lock_.unlock();
    }
}

struct Locked(T) {
    private T val;
    private Spinlock lock_;

    struct Guard {
        private shared Locked!(T)* locked;
        ref T get() {
            return cast(T) locked.val;
        }
        ~this() {
            locked.lock_.unlock();
        }
        alias get this;
    }

    Guard lock() shared {
        lock_.lock();
        return Guard(&this);
    }
}
