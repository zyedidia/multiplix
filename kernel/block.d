module kernel.block;

import sys = kernel.sys;
import bits = ulib.bits;

import ulib.vector;

struct BlockAllocator {
    enum blocksize = sys.pagesize;
    static assert(blocksize >= sys.pagesize && blocksize % sys.pagesize == 0);

        // free list
    struct Free {
        Free* next;
    }

    struct Header {
        // head of free list
        Free* free_head;
        ulong alloc_slots;
        ulong total_slots;
        ulong block_idx;

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

    Vector!(Header*)[bits.msb(sys.pagesize) - 1] blocks;

    Opt!(T*) kalloc(T, Args...)(Args args) {
        // find a block for this type that has space.
        // TODO: we probably want to have a free list of blocks so that we don't
        // end up iterating over all blocks in the worst case.
        for (long i = blocks!T.length - 1; i >= 0; i--) {
            auto block = blocks!T[i];
            if (block.free_head != null) {
                // have a block for this type which is not full
                return Opt!(T*)(block.allocate!(T)());
            }
        }
        // no free blocks for this type, make a new one
        Header* block = make_block!(T)();
        if (block == null) {
            return Opt!(T*).none;
        }
        T* val = block.allocate!(T)();
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
        // round down to nearest page boundary to get the header for the block
        Header* hdr = cast(Header*) (cast(uintptr) val & (~0 << (bits.msb(sys.pagesize) - 1)));

        hdr.alloc_slots--;
        if (hdr.alloc_slots == 0) {
            // free the whole block
            blocks.unordered_remove(hdr.block_idx);
            alloc.kfree(hdr);
            return;
        }

        Free* fp = cast(Free*) val;
        fp.next = hdr.free_head;
        hdr.free_head = fp;
    }

    private Header* make_block(T)() {
        // need enough room to store the free next node in the data slot
        static assert(T.sizeof >= Free.sizeof, "block element is too small");

        auto block_ = alloc.kalloc_block(blocksize);
        if (!block_.has()) {
            return null;
        }
        Header* block = cast(Header*) block_.get();
        size_t nelem = (blocksize - Header.sizeof) / T.sizeof;
        T[] data = (cast(T*) (block + 1))[0 .. nelem];
        block.free_head = cast(Free*) &data[0];
        block.alloc_slots = 0;
        block.total_slots = nelem;

        // set up free list
        for (size_t i = 0; i < data.length - 1; i++) {
            Free* free = cast(Free*) &data[i];
            free.next = cast(Free*) &data[i+1];
        }
        (cast(Free*) &data[data.length - 1]).next = null;

        block.block_idx = blocks!T.length;
        blocks!T.append(block);

        return block;
    }
}
