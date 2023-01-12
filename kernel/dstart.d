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
        uintptr tls_start, stack_start;
        ubyte* heap = init_tls(coreid, tls_start, stack_start);
        cpuinfo.coreid = coreid;
        cpuinfo.tls = tls_start;
        cpuinfo.stack = stack_start;

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
            cpuinfo.primary = true;
        } else {
            cpuinfo.primary = false;
        }

        kmain(coreid, heap);
    }

    // returns a pointer to the region after all TLS blocks
    ubyte* init_tls(int coreid, out uintptr tls_start, out uintptr stack_start) {
        // Note: this function should not be inlined to ensure that the thread
        // pointer is set before any subsequent operations that involve the
        // thread pointer.
        pragma(LDC_never_inline);

        // set up thread-local storage (tls)
        uintptr stack_base = cast(uintptr) &_kheap_start;
        uintptr stack_start = stack_base + (coreid + 1) * 4096;
        uintptr tls_base = stack_base + System.ncores * 4096;

        size_t tls_size = (&_tbss_end - &_tdata_start) + arch.tcb_size;
        // calculate the start of the tls region for this cpu
        tls_start = tls_base + tls_size * coreid;
        size_t tdata_size = &_tdata_end - &_tdata_start;
        size_t tbss_size = &_tbss_end - &_tbss_start;
        // copy tdata into the tls region
        for (size_t i = 0; i < tdata_size; i++) {
            volatile_st(cast(ubyte*) tls_start + arch.tcb_size + i, volatile_ld(&_tdata_start + i));
        }
        // zero out the tbss
        for (size_t i = 0; i < tbss_size; i++) {
            volatile_st(cast(ubyte*) tls_start + arch.tcb_size + tdata_size + i, 0);
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
