module kernel.main;

import plix.print : printf;
import plix.fwi : wakeup_cores;
import plix.timer : Timer;

extern (C) void kmain(uint coreid, bool primary) {
    if (primary) {
        wakeup_cores();
    }

    printf("core: %u, entered kmain at: %p\n", coreid, &kmain);

    if (!primary) {
        return;
    }

    Timer.delay_ms(100);
    auto cycles = Timer.cycles();
    printf("%ld\n", cycles);
    Timer.delay_ms(500);
    printf("%ld\n", Timer.cycles() - cycles);
}
