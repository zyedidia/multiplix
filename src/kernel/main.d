module kernel.main;

import plix.print : printf, println;
import plix.fwi : wakeup_cores;
import plix.timer : Timer;
import plix.alloc : kallocinit, kalloc, kfree;

immutable ubyte[] hello = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) extern __gshared ubyte _heap_start;

extern (C) void kmain(uint coreid, bool primary) {
    if (primary) {
        wakeup_cores();
    }

    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);

    if (!primary) {
        return;
    }

    printf("%p\n", &_heap_start);
    kallocinit(&_heap_start, 8 * 4096);
    {
        ubyte[] x = kalloc(16);
        printf("%p\n", x.ptr);
    }
    {
        ubyte[] x = kalloc(16);
        printf("%p\n", x.ptr);
    }
    {
        ubyte[] x = kalloc(4096);
        printf("%p\n", x.ptr);
        kfree(x);
    }
    {
        ubyte[] x = kalloc(4096);
        printf("%p\n", x.ptr);
    }
    {
        ubyte[] x = kalloc(8192);
        printf("8192: %p\n", x.ptr);
    }
    {
        ubyte[] x = kalloc(8192);
        printf("8192: %p\n", x.ptr);
    }
}
