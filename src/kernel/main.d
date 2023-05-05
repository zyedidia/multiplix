module kernel.main;

import plix.print : printf;
import plix.fwi : wakeup_cores;

extern (C) void kmain(uint coreid, bool primary) {
    if (primary) {
        wakeup_cores();
        wakeup_cores();
        wakeup_cores();
        wakeup_cores();
    }

    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);
}
