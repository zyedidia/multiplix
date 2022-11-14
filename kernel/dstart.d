module kernel.dstart;

import core.volatile;

import kernel.arch.riscv.start : start;
import kernel.main : kmain;
import sys = ulib.sys;

extern (C) extern __gshared uint _kbss_start, _kbss_end;

extern (C) void dstart() {
    uint* bss = &_kbss_start;
    uint* bss_end = &_kbss_end;

    while (bss < bss_end) {
        volatileStore(bss++, 0);
    }

    start(cast(uintptr) &kmain);
    sys.exit(0);
}
