module kernel.alloc.checkpoint;

import ulib.vector;

// Checkpoint allocator (records allocations in a vector allowing you to free
// them all at once).
struct CkptAllocator(A) {
    A* internal;

    this(A* a) {
        internal = a;
    }

    void construct(Args...)(Args args) {
        internal.__ctor(args);
    }

    // This vector is backed by the system allocator (used by ulib).
    Vector!(void*) allocs;
    bool active;

    void* alloc(size_t sz) {
        void* p = internal.alloc(sz);
        if (p && active) {
            if (!allocs.append(p)) {
                internal.free(p);
                return null;
            }
        }
        return p;
    }

    void free(void* p) {
        internal.free(p);
    }

    // start a checkpoint
    void ckpt() {
        active = true;
    }

    // free all allocations since the last checkpoint
    void free_ckpt() {
        foreach (p; allocs) {
            internal.free(p);
        }
        allocs.clear();
        active = false;
    }

    // finished checkpoint without freeing (only frees the underlying
    // allocation vector)
    void done_ckpt() {
        allocs.clear();
    }
}
