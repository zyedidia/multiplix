module dstart;

import core.volatile;

static import kernel;

extern (C) extern __gshared uint _kbss_start, _kbss_end;

extern (C) void dstart() {
    uint* bss = &_kbss_start;
    uint* bss_end = &_kbss_end;

    while (bss < bss_end) {
        volatileStore(bss++, 0);
    }

    kernel.kmain();
    kernel.shutdown();
}
