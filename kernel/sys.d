module kernel.sys;

import kernel.board;

enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum mb(ulong n) = 1024 * 1024 * n;
enum highmem_base = 0xFFFF_FFC0_0000_0000;
enum size_t pagesize = 4096;

version (kernel) {
    import kernel.alloc.buddy;
    import kernel.alloc.block;

    alias Buddy = BuddyAllocator!(pagesize, Machine.memsize);
    __gshared Buddy buddy;

    alias Block = BlockAllocator!(typeof(buddy));
    __gshared Block block = Block(&buddy);

    alias allocator = block;
} else version (monitor) {
    import kernel.alloc.kr;

    __gshared KrAllocator kr;
    alias allocator = kr;
}
