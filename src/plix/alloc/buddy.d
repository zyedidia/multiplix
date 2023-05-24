module plix.alloc.buddy;

import core.math : max, min, pow2ceil, log2ceil;

enum MIN_HEAP_ALIGN = 4096;

struct FreeBlock {
    FreeBlock* next;
}

struct BuddyAlloc(usize N) {
    ubyte[] heap;
    FreeBlock*[N] free_lists;
    usize min_block_size;
    usize min_block_size_log2;

    void initialize(ubyte[] heap) {
        this.heap = heap;
        min_block_size = heap.length >> (N - 1);
        min_block_size_log2 = log2ceil(min_block_size);
        // Insert the entire heap into the last free list.
        free_lists[N - 1] = cast(FreeBlock*) heap.ptr;
    }

    bool allocation_size(ref usize size, usize align_) {
        // TODO: assert align_ is power of 2
        assert(align_ <= MIN_HEAP_ALIGN);

        if (align_ > size) {
            size = align_;
        }

        size = max(size, min_block_size);
        size = pow2ceil(size);

        if (size > heap.length) {
            return false;
        }

        return true;
    }

    bool allocation_order(usize size, usize align_, ref usize order) {
        bool ok = allocation_size(size, align_);
        if (!ok) {
            return false;
        }
        order = log2ceil(size) - min_block_size_log2;
        return true;
    }

    usize order_size(usize order) {
        return 1 << (min_block_size_log2 + order);
    }

    ubyte* free_list_pop(usize order) {
        FreeBlock* fb = free_lists[order];
        if (fb) {
            if (order != free_lists.length - 1) {
                free_lists[order] = fb.next;
            } else {
                free_lists[order] = null;
            }

            return cast(ubyte*) fb;
        } else {
            return null;
        }
    }

    void free_list_insert(usize order, ubyte* block) {
        FreeBlock* fbp = cast(FreeBlock*) block;
        *fbp = FreeBlock(free_lists[order]);
        free_lists[order] = fbp;
    }

    bool free_list_remove(usize order, ubyte* block) {
        FreeBlock* block_ptr = cast(FreeBlock*) block;
        FreeBlock** checking = &free_lists[order];

        while (*checking) {
            if (*checking == block_ptr) {
                *checking = (*checking).next;
                return true;
            }

            checking = &(*checking).next;
        }
        return false;
    }

    void split_free_block(ubyte* block, usize order, usize order_needed) {
        usize size_to_split = order_size(order);

        while (order > order_needed) {
            size_to_split >>= 1;
            order -= 1;

            ubyte* split = block + size_to_split;
            free_list_insert(order, split);
        }
    }

    ubyte* buddy(usize order, ubyte* block) {
        assert(block >= heap.ptr);

        usize relative = block - heap.ptr;
        usize size = order_size(order);
        if (size >= heap.length) {
            return null;
        } else {
            return heap.ptr + (relative ^ size);
        }
    }

    usize alignment(usize size) {
        return size >= 4096 ? 4096 : 16;
    }

    ubyte[] alloc(usize size) {
        ubyte* p = allocate(size, alignment(size));
        return p[0 .. size];
    }

    ubyte* allocate(usize size, usize align_) {
        usize order_needed;
        if (!allocation_order(size, align_, order_needed)) {
            return null;
        }

        foreach (order; order_needed .. free_lists.length) {
            ubyte* block = free_list_pop(order);
            if (block) {
                if (order > order_needed) {
                    split_free_block(block, order, order_needed);
                }

                return block;
            }
        }

        return null;
    }

    void free(void* ptr, usize size) {
        dealloc(cast(ubyte*) ptr, size, alignment(size));
    }

    void dealloc(ubyte* ptr, usize size, usize align_) {
        usize initial_order;
        ensure(allocation_order(size, align_, initial_order));

        ubyte* block = ptr;
        foreach (order; initial_order .. free_lists.length) {
            ubyte* b = buddy(order, block);
            if (b) {
                if (free_list_remove(order, b)) {
                    block = min(block, b);
                    continue;
                }
            }

            free_list_insert(order, block);
            return;
        }
    }
}
