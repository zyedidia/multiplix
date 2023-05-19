module plix.alloc.buddy;

struct FreeBlock {
    FreeBlock* next;
}

struct BuddyAlloc(usize N) {
    ubyte[] heap;
    FreeBlock[N] free_lists;
    usize min_block_size;
    ubyte min_block_size_log2;
}
