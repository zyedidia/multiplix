module kernel.dstart;

import core.volatile;

import kernel.board;

extern (C) {
    extern __gshared uint _kbss_start, _kbss_end;

    void kmain();

    void dstart() {
        uint* bss = &_kbss_start;
        uint* bss_end = &_kbss_end;
        while (bss < bss_end) {
            volatile_st(bss++, 0);
        }
        kmain();
    }

    void ulib_tx(ubyte c) {
        Uart.tx(c);
    }

    void ulib_exit() {
    }
}
