module plix.alloc.bump;

import core.math : align_off;

// Bump allocator (does not support free)
struct BumpAlloc(usize alignment = 16) {
    this(ubyte* heap_start, usize size) {
        uintptr base = cast(uintptr) heap_start;
        base += align_off(base, alignment);
        assert(base + size >= base);
        this.base = base;
        this.end = base + size;
        assert(this.base % alignment == 0);
        assert(this.end % alignment == 0);
    }

    void* alloc(usize sz) {
        assert(sz + align_off(sz, alignment) >= sz);
        sz += align_off(sz, alignment);
        assert(base + sz >= base);
        if (base + sz > end) {
            return null;
        }

        void* ptr = cast(void*) base;
        base += sz;
        return ptr;
    }

    void free(void* ptr) {
        // no free
    }

private:
    uintptr base;
    uintptr end;
}
