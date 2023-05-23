module plix.guard;

import plix.arch.trap : Irq;
import plix.spinlock : Spinlock;

struct IrqGuard {
    bool irqs;

    static IrqGuard get() {
        bool irqs = Irq.enabled();
        Irq.off();
        return IrqGuard(irqs);
    }

    ~this() {
        if (irqs) {
            Irq.on();
        }
    }
}

struct SpinGuard {
    shared Spinlock* lock;
    bool irqs;

    static SpinGuard get(shared Spinlock* lock) {
        bool irqs = lock.lock();
        return SpinGuard(lock, irqs);
    }

    ~this() {
        lock.unlock(irqs);
    }
}
