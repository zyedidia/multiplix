module plix.alloc.kr;

// K&R allocator
struct KrAlloc(uint alignment) {
    struct Header {
        align(alignment)
        Header* ptr; // next block if on free list
        usize size; // size of this block
    }

    Header base;
    Header* freep;
    ubyte* heap;
    ubyte* heap_end;

    this(ubyte* heap_start, usize size) {
        this.heap = heap_start;
        this.heap_end = heap_start + size;
    }

    private void* sbrk(usize increment) {
        if (heap >= heap_end) {
            return null;
        }
        void* p = cast(void*) heap;
        heap += increment;
        return p;
    }

    enum nalloc = 1; // minimum number of units to request
    private Header* morecore(usize nu) {
        if (nu < nalloc) {
            nu = nalloc;
        }
        Header* up = cast(Header*) sbrk(nu * Header.sizeof);
        if (!up) {
            return null;
        }
        up.size = nu;
        free_internal(cast(void*) (up+1));
        return freep;
    }

    void* alloc(usize nbytes) {
        usize nunits = (nbytes + Header.sizeof-1)/Header.sizeof + 1;
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
        if (!ap)
            return;

        free_internal(ap);
    }

    private void free_internal(void* ap) {
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
