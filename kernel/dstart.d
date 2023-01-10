module kernel.dstart;

import core.volatile;

import kernel.board;
import kernel.cpu;

import arch = kernel.arch;

import ulib.memory;

__gshared uint primary = 1;

extern (C) {
    extern __gshared uint _kbss_start, _kbss_end;
    extern __gshared ubyte _kheap_start;
    extern __gshared ubyte _tdata_start, _tdata_end;
    extern __gshared ubyte _tbss_start, _tbss_end;

    void kmain(int coreid, ubyte* heap);

    void dstart(int coreid) {
        // We use volatile for loading/storing primary because it is essential
        // that primary not be stored in the BSS (since it is used before BSS
        // initialization). Otherwise the compiler will actually invert primary
        // so that it can be stored in the BSS (seems like an aggressive
        // optimization?).
        /* bool maincpu = volatile_ld(&primary) == 1; */
        if (volatile_ld(&primary)) {
            uint* bss = &_kbss_start;
            uint* bss_end = &_kbss_end;
            while (bss < bss_end) {
                volatile_st(bss++, 0);
            }

            Uart.init(115200);
            volatile_st(&primary, 0);
        }

        ubyte* heap = init_tls(coreid);

        cpuinfo.coreid = coreid;
        /* cpuinfo.primary = maincpu; */

        kmain(coreid, heap);
    }

    // returns a pointer to the region after all TLS blocks
    ubyte* init_tls(int coreid) {
        // Note: this function should not be inlined to ensure that the thread
        // pointer is set before any subsequent operations that involve the
        // thread pointer.
        pragma(LDC_never_inline);

        // set up thread-local storage (tls)
        uintptr stack_base = cast(uintptr) &_kheap_start;
        uintptr tls_base = stack_base + System.ncores * 4096;

        size_t tls_size = (&_tbss_end - &_tdata_start) + arch.tcb_size;
        // calculate the start of the tls region for this cpu
        ubyte* tls_start = cast(ubyte*) (tls_base + tls_size * coreid);
        size_t tdata_size = &_tdata_end - &_tdata_start;
        size_t tbss_size = &_tbss_end - &_tbss_start;
        // copy tdata into the tls region
        for (size_t i = 0; i < tdata_size; i++) {
            volatile_st(tls_start + arch.tcb_size + i, volatile_ld(&_tdata_start + i));
        }
        // zero out the tbss
        for (size_t i = 0; i < tbss_size; i++) {
            volatile_st(tls_start + arch.tcb_size + tdata_size + i, 0);
        }

        arch.set_tls_base(tls_start);

        return cast(ubyte*) (tls_base + tls_size * System.ncores);
    }

    void ulib_tx(ubyte c) {
        Uart.tx(c);
    }

    void ulib_exit() {
    }
}
