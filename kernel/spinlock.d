module kernel.spinlock;

import core.sync;

import kernel.irq;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked = 0;

    // Acquire the lock.
    shared void lock() {
        Irq.push_off(); // disable interrupts to avoid deadlock

        while (!atomic_cmp_xchg(&locked, 0, 1)) {
        }
        memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        memory_fence();
        atomic_store(0, &locked);

        Irq.pop_off();
    }
}
