module plix.sleeplock;

import plix.spinlock : Spinlock;

// TODO: sleeplock is incomplete

struct Sleeplock {
    bool locked;
    Spinlock lock_;

    shared void lock() {
        auto l = lock_.lock();
        while (locked) {
            // sleep
        }
        locked = true;
        lock_.unlock(l);
    }

    shared void unlock() {
        auto l = lock_.lock();
        locked = false;
        // wakeup
        lock_.unlock(l);
    }
}
