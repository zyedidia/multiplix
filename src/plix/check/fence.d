module plix.check.fence;

import core.hashmap : Hashmap, eq, hash;
import core.exception : panic, panicf;

struct FenceCheck {
    Hashmap!(uintptr, bool, hash, eq) mem;

    bool setup() {
        return Hashmap!(uintptr, bool, hash, eq).alloc(&mem, 1024);
    }

    void on_store(uintptr pa, uintptr epc) {
        if (!mem.put(pa, true)) {
            panicf("fence: out of memory");
        }
    }

    void on_exec(uintptr va, uintptr pa) {
        if (mem.get(pa, null)) {
            panicf("fence: executed %lx (va: %lx) without preceding fence", pa, va);
        }
    }

    void on_fence() {
        mem.clear();
    }
}
