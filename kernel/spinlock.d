module kernel.spinlock;

import core.sync;

import kernel.cpu;
import kernel.irq;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked = 0;
    Cpu* cpu;

    // Acquire the lock.
    shared void lock() {
        Irq.push_off(); // disable interrupts to avoid deadlock
        assert(!holding());

        import kernel.board;
        while (lock_test_and_set(&locked, 1) != 0) {
        }
        memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        assert(holding());
        memory_fence();
        lock_release(&locked);

        Irq.pop_off();
    }

    shared bool holding() in (!Irq.is_on()) {
        return locked && this.cpu == cpu;
    }
}
