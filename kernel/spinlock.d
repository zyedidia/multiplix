module kernel.spinlock;

import kernel.trap;

import core.atomic;

bool intr;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked;

    // Acquire the lock.
    shared void lock() {
        Trap.pushDisable();
        while (!llvm_atomic_cmp_xchg(&locked, 0, 1).exchanged) {
        }
        llvm_memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        llvm_memory_fence();
        llvm_atomic_store(0, &locked);
        Trap.popDisable();
    }
}
