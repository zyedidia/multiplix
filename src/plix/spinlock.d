module plix.spinlock;

import core.atomic : atomic_test_and_set, atomic_clear;

import plix.arch.trap : Irq;

// Basic mutual exclusion spinlock.
struct Spinlock {
    shared ubyte locked = 0;

    shared bool lock() {
        bool irqen = Irq.enabled();
        Irq.off();
        while (atomic_test_and_set(&locked) != false) {
        }
        return irqen;
    }

    shared void unlock(bool irqen) {
        atomic_clear(&locked);
        if (irqen)
            Irq.on();
    }
}

// Protects some data with a spinlock. The data is only accessible through a
// guard object.
struct SpinProtect(T) {
    private T val;
    private Spinlock lock_;

    this(T v) {
        val = v;
    }

    struct Guard {
        private shared SpinProtect!(T)* locked;
        bool irqen;
        bool moved;
        this(ref return scope Guard g) {
            g.moved = true;
        }
        pragma(inline, true)
        ref T val() {
            // Cast away the shared.
            return *cast(T*) &locked.val;
        }
        ~this() {
            if (!moved)
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
