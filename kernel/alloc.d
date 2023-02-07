module kernel.alloc;

import ulib.alloc;
import ulib.option;
import ulib.vector;

import kernel.board;

// K&R allocator
struct KrAllocator {
    struct Header {
        align(16)
        Header* ptr; // next block if on free list
        size_t size; // size of this block
    }

    Header base;
    Header* freep;
    ubyte* heap;
    ubyte* heap_end;

    this(ubyte* heap_start, size_t size) {
        this.heap = heap_start;
        this.heap_end = heap_start + size;
    }

    void* sbrk(size_t increment) {
        if (heap >= heap_end) {
            return null;
        }
        void* p = cast(void*) heap;
        heap += increment;
        return p;
    }

    enum nalloc = 1024; // minimum number of bytes to request
    Header* morecore(size_t nu) {
        if (nu < nalloc) {
            nu = nalloc;
        }
        Header* up = cast(Header*) sbrk(nu * Header.sizeof);
        if (!up) {
            return null;
        }
        up.size = nu;
        free(cast(void*) (up+1));
        return freep;
    }

    void* alloc(size_t nbytes) {
        size_t nunits = (nbytes + Header.sizeof-1)/Header.sizeof + 1;
        Header* prevp = void;
        Header* p = void;
        if ((prevp = freep) == null) { // no free list yet
            base.ptr = freep = prevp = &base;
            base.size = 0;
        }
        for (p = prevp.ptr; ; prevp = p, p = p.ptr) {
            if (p.size >= nunits) { // big enough
                if (p.size == nunits) { // exactly
                    prevp.ptr = p.ptr;
                } else {
                    p.size -= nunits;
                    p += p.size;
                    p.size = nunits;
                }
                freep = prevp;
                return cast(void*) (p+1);
            }
            if (p == freep) // wrapped around free list
                if ((p = morecore(nunits)) == null)
                    return null; // none left
        }
    }

    void free(void* ap) {
        Header* bp = cast(Header*) ap - 1; // point to block header
        Header* p = void;
        for (p = freep; !(bp > p && bp < p.ptr); p = p.ptr) {
            if (p >= p.ptr && (bp > p || bp < p.ptr)) {
                break; // freed block at start or end of arena
            }
        }
        if (bp + bp.size == p.ptr) { // join to upper nbr
            bp.size += p.ptr.size;
            bp.ptr = p.ptr.ptr;
        } else {
            bp.ptr = p.ptr;
        }
        if (p + p.size == bp) { // join to lower nbr
            p.size += bp.size;
            p.ptr = bp.ptr;
        } else {
            p.ptr = bp;
        }
        freep = p;
    }
}

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

struct CheckpointAllocator(A) {
    A* internal;

    this(A* a) {
        internal = a;
    }

    void construct(Args...)(Args args) {
        internal.__ctor(args);
    }

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

    void checkpoint() {
        active = true;
    }

    void free_checkpoint() {
        foreach (p; allocs) {
            internal.free(p);
        }
        allocs.clear();
        active = false;
    }

    void done_checkpoint() {
        allocs.clear();
    }
}

// Allocation API.

// void* kalloc(size_t sz)
// T* knew(T, Args...)(Args args)
// T[] knew_array(T, Args...)(size_t nelem, Args args)
// void kfree(T)(T* ptr)

struct Alloc(A) {
    // Allocates a new block of `sz` bytes. Returns null if failed.
    static void* kalloc(A* allocator, size_t sz) {
        return allocator.alloc(sz);
    }

    // Allocates a new object of type T. Args passed to T.constructor. Returns
    // null if failed.
    static T* knew(T, Args...)(A* allocator, Args args) {
        T* p = cast(T*) allocator.alloc(T.sizeof);
        if (!p) {
            return null;
        }
        if (!emplace_init(p, args)) {
            allocator.free(p);
            return null;
        }
        return p;
    }

    // Allocates a new array of type T and of size nelem. Args passed to
    // T.constructor. Returns null if failed.
    static T[] knew_array(T, Args...)(A* allocator, size_t nelem, Args args) {
        T* p = cast(T*) allocator.alloc(T.sizeof * nelem);
        if (!p) {
            return null;
        }
        T[] arr = cast(T[]) p[0 .. nelem];
        for (int i = 0; i < arr.length; i++) {
            if (!emplace_init(&arr[i], args)) {
                allocator.free(p);
                return null;
            }
        }
        return arr;
    }

    // Calls the destructor for ptr and frees the memory.
    static void kfree(T)(A* allocator, T* ptr) {
        static if (HasDtor!T) {
            ptr.__xdtor();
        }
        allocator.free(cast(void*) ptr);
    }
}

// Allocation API using a custom allocator.

void* kalloc_custom(A)(A* allocator, size_t sz) {
    return Alloc!(A).kalloc(allocator, sz);
}

T* knew_custom(T, A, Args...)(A* allocator, Args args) {
    return Alloc!(A).knew!(T)(allocator, args);
}

T[] knew_array_custom(T, A, Args...)(A* allocator, size_t nelem, Args args) {
    return Alloc!(A).knew_array!(T)(allocator, args);
}

void kfree_custom(T, A)(A* allocator, T* ptr) {
    Alloc!(A).kfree!(T)(allocator, ptr);
}

// Allocation API using the system allocator.

alias SystemAlloc = Alloc!(typeof(System.allocator));

void* kalloc(size_t sz) {
    return SystemAlloc.kalloc(&System.allocator, sz);
}

T* knew(T, Args...)(Args args) {
    return SystemAlloc.knew!(T)(&System.allocator, args);
}

T[] knew_array(T, Args...)(size_t nelem, Args args) {
    return SystemAlloc.knew_array!(T)(&System.allocator, nelem, args);
}

void kfree(T)(T* ptr) {
    SystemAlloc.kfree(&System.allocator, ptr);
}

extern (C) {
    void* ulib_malloc(size_t sz) {
        return System.allocator.alloc(sz);
    }

    void ulib_free(void* p) {
        System.allocator.free(p);
    }
}
