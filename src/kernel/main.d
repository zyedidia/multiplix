module kernel.main;

import plix.print : printf;

extern (C) void kmain(uint coreid, bool primary) {
    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);
}
