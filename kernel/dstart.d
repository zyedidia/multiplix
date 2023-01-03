module kernel.dstart;

import core.volatile;

import kernel.board;
import kernel.spinlock;

shared Spinlock bootlock;

__gshared bool primary = true;

extern (C) {
    extern __gshared uint _kbss_start, _kbss_end;

    void kmain(int coreid);

    void dstart(int coreid) {
        bootlock.lock();

        if (primary) {
            uint* bss = &_kbss_start;
            uint* bss_end = &_kbss_end;
            while (bss < bss_end) {
                volatile_st(bss++, 0);
            }
            Uart.init(115200);

            primary = false;
        }

        bootlock.unlock();

        kmain(coreid);
    }

    void ulib_tx(ubyte c) {
        Uart.tx(c);
    }

    void ulib_exit() {
    }
}
