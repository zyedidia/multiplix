module kernel.check.conc;

import core.exception;
import core.vector;
import plix.spinlock;
import plix.timer;
import plix.cpu;
import plix.arch.cpu : rdcpu;

private bool overlaps(uintptr a1, size_t sz1, uintptr a2, size_t sz2) {
    return a1 < a2+sz2 && a2 < a1+sz1;
}

// Concurrency checker
struct ConcChecker {
    struct Watchpoint {
        ulong core;
        uintptr addr;
        size_t size;
    }

    // Would this ever be large enough to warrant a hashmap instead?
    Vector!(Watchpoint) watchpoints;
    shared Spinlock lock;

    void on_access(uintptr addr, size_t size, uintptr epc) {
        auto irqs = lock.lock();
        ulong cpu = rdcpu();
        foreach (ref watched; watchpoints) {
            if (overlaps(addr, size, watched.addr, watched.size)) {
                // Lock is still held into the panic.
                panicf("core: %ld, data race: simultaneous access to %p (at %p) (watchpoint: %ld, %p, %lx)\n",
                        cpu, cast(void*) addr, cast(void*) epc, watched.core, cast(void*) watched.addr, watched.size);
            }
        }
        ensure(watchpoints.append(Watchpoint(cpu, addr, size)));
        lock.unlock(irqs);
        Timer.delay_us(10);

        // Done waiting for data race to occur.
        irqs = lock.lock();
        for (int i = 0; i < watchpoints.length; i++) {
            if (watchpoints[i].core == cpu) {
                watchpoints.unordered_remove(i);
                break;
            }
        }
        lock.unlock(irqs);
    }
}

