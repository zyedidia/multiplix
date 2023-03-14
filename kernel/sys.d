module kernel.sys;

import kernel.board;

enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum mb(ulong n) = 1024 * 1024 * n;
enum highmem_base = 0xFFFF_FFC0_0000_0000;
enum size_t pagesize = 4096;

version (kernel) {
    import kernel.alloc.buddy;
    import kernel.alloc.block;

    // The kernel's system allocator is a block allocator wrapped around a
    // buddy allocator.
    alias Buddy = BuddyAllocator!(pagesize, Machine.main_memory.start, Machine.main_memory.sz);
    __gshared Buddy buddy;

    alias Block = BlockAllocator!(typeof(buddy));
    __gshared Block block = Block(&buddy);

    alias allocator = block;
} else version (monitor) {
    import kernel.alloc.kr;

    // The monitor's system allocator is a simple K&R allocator.
    __gshared KrAllocator kr;
    alias allocator = kr;
}
