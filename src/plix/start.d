module plix.start;

import plix.cpu : init_cpu;
import plix.board : setup;

extern (C) {
    extern __gshared uint _bss_start, _bss_end;

    void kmain(uint, bool);

    void start(uint coreid, bool primary) {
        if (primary) {
            init_bss();
        }

        init_cpu(coreid, primary);

        setup();

        kmain(coreid, primary);
    }
}

private void init_bss() {
    uint* bss = &_bss_start;
    uint* bss_end = &_bss_end;
    while (bss < bss_end) {
        *bss++ = 0;
    }
}
