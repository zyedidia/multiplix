module plix.spinlock;

import core.atomic : atomic_test_and_set, atomic_clear;

import plix.arch.trap : irq;

// Basic mutual exclusion spinlock.
struct Spinlock {
    shared ubyte locked = 0;

    shared bool lock() {
        bool irqen = irq.enabled();
        while (atomic_test_and_set(&locked) != false) {
        }
        return irqen;
    }

    shared void unlock(bool irqen) {
        atomic_clear(&locked);
        if (irqen)
            irq.on();
    }
}

// Guards some data with a spinlock. The data is only accessible through a
// guard object.
struct SpinGuard(T) {
    private T val;
    private Spinlock lock_;

    this(T v) {
        val = v;
    }

    struct Guard {
        private shared SpinGuard!(T)* locked;
        bool irqen;
        pragma(inline, true)
        ref T val() {
            // Cast away the shared.
            return *cast(T*) &locked.val;
        }
        ~this() {
            locked.lock_.unlock(irqen);
        }
        alias val this;
    }

    pragma(inline, true)
    Guard lock() shared {
        bool irqen = lock_.lock();
        return Guard(&this, irqen);
    }
}