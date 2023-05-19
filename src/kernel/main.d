module kernel.main;

import plix.print : printf, println;
import plix.fwi : wakeup_cores;
import plix.timer : Timer;

immutable ubyte[] hello = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) void kmain(uint coreid, bool primary) {
    if (primary) {
        wakeup_cores();
    }

    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);

    if (!primary) {
        return;
    }
}
