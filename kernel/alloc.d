module kernel.alloc;

import ulib.option;

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

import kernel.board;
import ulib.alloc;

// Allocation API.

Opt!(void*) kalloc_block(A)(A* allocator, size_t sz) {
    return Opt!(void*)(allocator.alloc(sz));
}

Opt!(T*) kalloc(A, T, Args...)(A* allocator, Args args) {
    T* p = cast(T*) allocator.alloc(T.sizeof);
    if (!p) {
        return Opt!(T*).none;
    }
    emplace_init(p, args);
    return Opt!(T*)(p);
}

Opt!(T[]) kalloc_array(A, T, Args...)(A* allocator, size_t nelem, Args args) {
    T* p = cast(T*) allocator.alloc(T.sizeof * nelem);
    T[] arr = cast(T[]) p[0 .. nelem];
    for (int i = 0; i < arr.length; i++) {
        emplace_init(&arr[i], args);
    }
    return arr;
}

void kfree(A)(A* allocator, void* ptr) {
    allocator.free(ptr);
}

// Allocation functions using the system allocator.

Opt!(void*) kalloc_block(size_t sz) {
    return kalloc_block(&System.allocator, sz);
}

Opt!(T*) kalloc(T, Args...)(Args args) {
    return kalloc!(typeof(System.allocator), T, Args)(&System.allocator, args);
}

Opt!(T[]) kalloc_array(T, Args...)(size_t nelem, Args args) {
    return kalloc_array(typeof(System.allocator), T, Args)(&System.allocator, nelem, args);
}

void kfree(void* ptr) {
    kfree(&System.allocator, ptr);
}
