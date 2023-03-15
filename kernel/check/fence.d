module kernel.check.fence;

import kernel.spinlock;
import ulib.hashmap;
import core.exception;

struct FenceChecker {
    Hashmap!(uintptr, bool, hash, eq) mem;
    shared Spinlock lock;

    bool setup() {
        return Hashmap!(uintptr, bool, hash, eq).alloc(&mem, 1024);
    }

    void on_store(uintptr pa, uintptr epc) shared {
        lock.lock();
        if (!(cast()mem).put(pa, true)) {
            panic("fence: out of memory");
        }
        lock.unlock();
    }

    void on_exec(uintptr va, uintptr pa) shared {
        lock.lock();
        if ((cast()mem).get(pa, null)) {
            panicf("fence: executed %lx (va: %lx) without preceding fence", pa, va);
        }
        lock.unlock();
    }

    void on_fence() shared {
        lock.lock();
        (cast()mem).clear();
        lock.unlock();
    }
}
