module boot.boot;

import plix.print : printf;
import plix.cpu : cpu;
import plix.alloc : kinit, kalloc, kfree, knew;
import plix.timer : Timer;
import plix.board : reboot;

import core.sync : Unguard;

extern (C) extern __gshared ubyte _heap_start;

shared Unguard!(int) x;

extern (C) void kmain(uint coreid, bool primary) {
    kinit(&_heap_start, 4096 * 4096);

    printf("%d: hello world\n", cpu.id);

    for (int i = 0; i < 5; i++) {
        ubyte[] x = kalloc(1024);
        printf("allocated: %p\n", x.ptr);
    }

    for (int i = 0; i < 5; i++) {
        printf("%d\n", i);
        Timer.delay_ms(500);
    }

    reboot.shutdown();
}
