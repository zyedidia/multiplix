module kernel.spinlock;

import core.sync;

import kernel.irq;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked = 0;

    // Acquire the lock.
    shared void lock() {
        Irq.push_off(); // disable interrupts to avoid deadlock

        while (lock_test_and_set(&locked, 1) != 0) {
        }
        memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        memory_fence();
        lock_release(&locked);

        Irq.pop_off();
    }
}
