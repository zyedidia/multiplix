module kernel.slab;

import alloc = kernel.alloc;

import sys = kernel.sys;

import ulib.alloc;
import ulib.option;
import ulib.vector;
import bits = ulib.bits;

struct SlabAllocator {
    enum slabsize = sys.pagesize;

    // free list
    struct Free {
        Free* next;
    }

    struct Header {
        // id of the type
        immutable(char)* tid;
        // head of free list
        Free* free_head;
        ulong alloc_slots;
        ulong slab_idx;

        T* allocate(T)() {
            if (free_head == null) {
                return null;
            }
            auto alloc = cast(T*) free_head;
            free_head = free_head.next;
            alloc_slots++;
            return alloc;
        }
    }

    Vector!(Header*) slabs;

    Opt!(T*) kalloc(T, Args...)(Args args) {
        foreach (slab; slabs) {
            if (T.mangleof.ptr == slab.tid && slab.free_head != null) {
                // have a slab for this type which is not full
                return Opt!(T*)(slab.allocate!(T)());
            }
        }
        // no free slabs for this type, make a new one
        Header* slab = make_slab!(T)();
        if (slab == null) {
            return Opt!(T*).none;
        }
        T* val = slab.allocate!(T)();
        if (val == null) {
            return Opt!(T*).none;
        }
        emplace_init(val, args);
        return Opt!(T*)(val);
    }

    void kfree(T)(T* val) {
        if (val == null) {
            return;
        }
        // round down to nearest page boundary to get the header for the slab
        Header* hdr = cast(Header*) (cast(uintptr) val & (~0 << (bits.msb(sys.pagesize) - 1)));

        hdr.alloc_slots--;
        if (hdr.alloc_slots == 0) {
            // free the whole slab
            slabs.unordered_remove(hdr.slab_idx);
            alloc.kfree(hdr);
            return;
        }

        Free* fp = cast(Free*) val;
        fp.next = hdr.free_head;
        hdr.free_head = fp;
    }

    private Header* make_slab(T)() {
        // need enough room to store the free next node in the data slot
        static assert(T.sizeof >= Free.sizeof);

        auto slab_ = alloc.kalloc_block(slabsize);
        if (!slab_.has()) {
            return null;
        }
        Header* slab = cast(Header*) slab_.get();
        slab.tid = T.mangleof.ptr;
        size_t nelem = (slabsize - Header.sizeof) / T.sizeof;
        T[] data = (cast(T*) (slab + 1))[0 .. nelem];
        slab.free_head = cast(Free*) &data[0];
        slab.alloc_slots = 0;

        // set up free list
        for (size_t i = 0; i < data.length - 1; i++) {
            Free* free = cast(Free*) &data[i];
            free.next = cast(Free*) &data[i+1];
        }
        (cast(Free*) &data[data.length - 1]).next = null;

        slab.slab_idx = slabs.length;
        slabs.append(slab);

        return slab;
    }
}
