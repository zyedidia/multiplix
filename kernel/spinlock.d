module kernel.spinlock;

import core.sync;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked = 0;

    // Acquire the lock.
    shared void lock() {
        while (!atomic_cmp_xchg(&locked, 0, 1).exchanged) {
        }
        memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        memory_fence();
        atomic_store(0, &locked);
    }
}
