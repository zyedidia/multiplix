module kernel.dstart;

import core.volatile;

import kernel.board;

__gshared uint primary = 1;

extern (C) {
    extern __gshared uint _kbss_start, _kbss_end;

    void kmain(int coreid);

    void dstart(int coreid) {
        // We use volatile for loading/storing primary because it is essential
        // that primary not be stored in the BSS (since it is used before BSS
        // initialization). Otherwise the compiler will actually invert primary
        // so that it can be stored in the BSS (seems like an aggressive
        // optimization?).
        if (volatile_ld(&primary)) {
            uint* bss = &_kbss_start;
            uint* bss_end = &_kbss_end;
            while (bss < bss_end) {
                volatile_st(bss++, 0);
            }
            Uart.init(115200);
            volatile_st(&primary, 0);
        }

        kmain(coreid);
    }

    void ulib_tx(ubyte c) {
        Uart.tx(c);
    }

    void ulib_exit() {
    }
}
