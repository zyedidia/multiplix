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
        int core;
        uintptr addr;
        size_t size;
    }

    // Would this ever be large enough to warrant a hashmap instead?
    Vector!(Watchpoint) watchpoints;
    shared Spinlock lock;

    void on_access(uintptr addr, size_t size, uintptr epc) {
        lock.lock();
        foreach (ref watched; watchpoints) {
            if (overlaps(addr, size, watched.addr, watched.size)) {
                // Lock is still held into the panic.
                panicf("core: %d, data race: simultaneous access to %p (at %p) (watchpoint: %d, %p, %lx)\n", cpu.coreid, cast(void*) addr, cast(void*) epc, watched.core, cast(void*) watched.addr, watched.size);
            }
        }
        // import ulib.print;
        // printf("core: %d, access: %p\n", cpu.coreid, cast(void*) addr);
        assert(watchpoints.append(Watchpoint(cpu.coreid, addr, size)));
        lock.unlock();
        Timer.delay_us(10);

        // Done waiting for data race to occur.
        lock.lock();
        for (int i = 0; i < watchpoints.length; i++) {
            if (watchpoints[i].core == cpu.coreid) {
                watchpoints.unordered_remove(i);
                break;
            }
        }
        lock.unlock();
    }
}
