module kernel.check.conc;

import core.exception;
import ulib.vector;
import kernel.spinlock;
import kernel.timer;
import kernel.cpu;

private bool overlaps(uintptr a1, size_t sz1, uintptr a2, size_t sz2) {
    return a1 < a2+sz2 && a2 < a1+sz1;
}

struct ConcChecker {
    struct Watchpoint {
        uintptr addr;
        size_t size;
    }

    // Would this ever be large enough to warrant a hashmap instead?
    Vector!(Watchpoint) watchpoints;
    shared Spinlock lock;

    void on_access(uintptr addr, size_t size, uintptr epc) shared {
        lock.lock();
        foreach (ref watched; (cast()watchpoints)) {
            if (overlaps(addr, size, watched.addr, watched.size)) {
                // Lock is still held into the panic.
                panicf("core: %d, data race: simultaneous access to %p (at %p)\n", cpu.coreid, cast(void*) addr, cast(void*) epc);
            }
        }
        // printf("core: %d, access: %p\n", cpu.coreid, cast(void*) addr);
        auto idx = (cast()watchpoints).length;
        assert((cast()watchpoints).append(Watchpoint(addr, size)));
        lock.unlock();
        Timer.delay_us(10);

        // Done waiting for data race to occur.
        lock.lock();
        (cast()watchpoints).unordered_remove(idx);
        lock.unlock();
    }
}
