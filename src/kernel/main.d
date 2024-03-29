module kernel.main;

import plix.print : printf, println;
import plix.fwi : wakeup_cores;
import plix.timer : Timer;
import plix.alloc : kallocinit, kalloc, kfree;
import plix.proc : Proc;
import plix.schedule : runq, schedule;
import plix.arch.trap : Irq;

import plix.fs.bcache : binit, Disk;
import plix.dev.disk.ramdisk : RamDisk;

import plix.sys : mb;

immutable ubyte[] hello_data = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) extern __gshared ubyte _heap_start;

extern (C) void coremark_main();

extern (C) void kmain(uint coreid, bool primary) {
    if (primary) {
        wakeup_cores();
    }

    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);

    if (!primary) {
        return;
    }

    kallocinit(&_heap_start, mb!(512));

    binit(Disk(&RamDisk.read, &RamDisk.write));
    import plix.fs.fs : fsinit;
    fsinit(1);

    ubyte[] hello = kalloc(hello_data.length);
    ensure(hello != null);
    import builtins : memcpy;
    memcpy(hello.ptr, hello_data.ptr, hello.length);

    for (int i = 0; i < 1; i++) {
        Proc* proc = Proc.make_from_elf(hello);
        ensure(proc != null);
        runq.push_front(proc);

        import plix.vm : PtIter;
        PtIter iter = PtIter.get(proc.pt);
        foreach (ref map; iter) {
            printf("%lx -> %lx\n", map.va, map.pa);
        }
    }

    Timer.intr(Timer.time_slice);
    Irq.on();

    schedule();
}
