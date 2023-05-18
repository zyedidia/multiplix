module plix.alloc.block;

import plix.spinlock : Spinlock;

import sys = plix.sys;
import bits = core.bits;

import core.math : log2ceil, pow2ceil;

struct BlockAllocator(A) {
    enum blocksize = sys.pagesize;
    static assert(blocksize >= sys.pagesize && blocksize % sys.pagesize == 0);

    enum nblocks = log2ceil(sys.pagesize);

    this(A* a) {
        allocator = a;
    }

    // call the underlying allocator's constructor.
    void construct(Args...)(Args args) {
        allocator.__ctor(args);
    }

    // free list
    struct Free {
        Free* next;
    }

    struct Header {
        // head of free list
        Free* free_head;
        uint alloc_slots;
        uint total_slots;
        Header* next;
        size_t size;

        void* allocate(size_t sz) {
            if (free_head == null) {
                return null;
            }
            void* alloc = cast(void*) free_head;
            free_head = free_head.next;
            alloc_slots++;
            size = sz;
            return alloc;
        }
    }

    shared Spinlock lock;
    A* allocator;
    Header*[nblocks] partial_blocks;
    Header*[nblocks] full_blocks;

    void* alloc(size_t sz) {
        // make sure the size is at least as large as a Free pointer.
        sz = sz < (Free*).sizeof ? sz = (Free*).sizeof : sz;
        // make sure size is a power of 2.
        sz = pow2ceil(sz);

        if (sz >= blocksize) {
            // size is big enough to go to the underlying allocator
            void* p = allocator.alloc(sz);
            return p;
        }

        lock.lock();
        scope(exit) lock.unlock();

        auto nblk = log2ceil(sz);
        // find a block for this size that has space.
        Header* block = partial_blocks[nblk];

        void* alloc_into(Header* block) {
            void* ptr = block.allocate(sz);
            if (ptr && block.alloc_slots >= block.total_slots) {
                // block became full so the new head of partial_blocks is the
                // next block.
                partial_blocks[nblk] = block.next;
                // insert this block into full_blocks
                block.next = full_blocks[nblk];
                full_blocks[nblk] = block;
            }
            return ptr;
        }

        if (block) {
            void* p = alloc_into(block);
            return p;
        }

        // no free blocks for this size, make a new one
        block = make_block(sz);
        if (!block) {
            return null;
        }
        // add it to the partial_blocks list.
        block.next = partial_blocks[nblk];
        partial_blocks[nblk] = block;
        void* p = alloc_into(block);
        return p;
    }

    void free(void* val) {
        if (val == null) {
            return;
        }

        if (cast(uintptr) val % sys.pagesize == 0) {
            // Page-aligned value must have been allocated by the underlying
            // allocator, so free it there.
            allocator.free(val);
            return;
        }

        lock.lock();
        scope(exit) lock.unlock();

        // round down to nearest page boundary to get the header for the block
        Header* hdr = cast(Header*) (cast(uintptr) val & (~0 << (bits.msb(sys.pagesize) - 1)));

        hdr.alloc_slots--;
        if (hdr.alloc_slots == 0) {
            // TODO: we could free the whole block. Currently the block
            // allocator never releases blocks back to the underlying
            // allocator.
        }

        // put this block back on the free list
        Free* fp = cast(Free*) val;
        fp.next = hdr.free_head;
        hdr.free_head = fp;
    }

    private Header* make_block(size_t sz) {
        Header* block = cast(Header*) allocator.alloc(blocksize);
        if (!block) {
            return null;
        }
        size_t nelem = (blocksize - Header.sizeof) / sz;
        size_t datasize = blocksize - Header.sizeof;
        ubyte[] data = (cast(ubyte*) (block + 1))[0 .. datasize];
        block.free_head = cast(Free*) &data[0];
        block.alloc_slots = 0;
        block.total_slots = cast(uint) nelem;

        // set up free list
        for (size_t i = 0; i < datasize - sz; i += sz) {
            Free* free = cast(Free*) &data[i];
            free.next = cast(Free*) &data[i+sz];
        }
        (cast(Free*) &data[datasize - sz]).next = null;

        return block;
    }
}
