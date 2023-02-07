module kernel.alloc.bump;

// Bump allocator (does not support free)
struct BumpAllocator(size_t alignment = 16) {
    private static uintptr align_off(uintptr ptr, size_t algn) {
        return ((~ptr) + 1) & (algn - 1);
    }

    this(ubyte* heap_start, size_t size) {
        uintptr base = cast(uintptr) heap_start;
        base += align_off(base, alignment);
        assert(base + size >= base);
        this.base = base;
        this.end = base + size;
        assert(this.base % alignment == 0);
        assert(this.end % alignment == 0);
    }

    void* alloc(size_t sz) {
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
