module kernel.main;

import plix.print : printf, println;
import plix.fwi : wakeup_cores;
import plix.timer : Timer;
import plix.alloc : kallocinit, kalloc, kfree;
import plix.proc : Proc;
import plix.schedule : runq, schedule;

import plix.sys : mb;

immutable ubyte[] hello_data = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) extern __gshared ubyte _heap_start;

extern (C) void kmain(uint coreid, bool primary) {
    if (primary) {
        wakeup_cores();
    }

    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);

    if (!primary) {
        return;
    }

    kallocinit(&_heap_start, mb!(512));

    ubyte[] hello = kalloc(hello_data.length);
    ensure(hello != null);
    import builtins : memcpy;
    memcpy(hello.ptr, hello_data.ptr, hello.length);

    Proc* proc = Proc.make_from_elf(hello);
    ensure(proc != null);
    runq.push_front(proc);

    schedule();
}
