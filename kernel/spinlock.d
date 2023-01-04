module kernel.spinlock;

import core.sync;

// Basic mutual exclusion lock.
struct Spinlock {
    // We use locks to synchronize initializing the BSS, so locks should not be
    // stored in the BSS.
    shared uint unlocked = 1;

    // Acquire the lock.
    shared void lock() {
        while (!atomic_cmp_xchg(&unlocked, 1, 0).exchanged) {
        }
        memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        memory_fence();
        atomic_store(1, &unlocked);
    }
}
