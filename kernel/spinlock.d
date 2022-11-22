module kernel.spinlock;

import core.atomic;

// Basic mutual exclusion lock.
struct Spinlock {
    shared uint locked;

    // Acquire the lock.
    shared void lock() {
        auto t = cast(Spinlock*) &this;
        while (!llvm_atomic_cmp_xchg(&t.locked, 0, 1).exchanged) {
        }
        llvm_memory_fence();
    }

    // Release the lock.
    shared void unlock() {
        auto t = cast(Spinlock*) &this;
        llvm_memory_fence();
        llvm_atomic_store(0, &t.locked);
    }
}
