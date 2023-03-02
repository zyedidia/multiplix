module kernel.dstart;

import core.volatile;

import kernel.cpu;

import libc;

__gshared uint primary = 1;

extern (C) {
    extern __gshared uint _kbss_start, _kbss_end;
    extern __gshared ubyte _kheap_start;
    extern __gshared ubyte _tdata_start, _tdata_end;
    extern __gshared ubyte _tbss_start, _tbss_end;

    void kmain(int coreid, ubyte* heap);

    import kernel.spinlock;
    shared Spinlock lock;


    void dstart(int coreid) {
        import kernel.board;

        uintptr stack_start;
        ubyte* heap = init_tls(coreid, stack_start);
        import core.sync;
        compiler_fence();

        // We use volatile for loading/storing primary because it is essential
        // that primary not be stored in the BSS (since it is used before BSS
        // initialization). Otherwise the compiler will actually invert primary
        // so that it can be stored in the BSS.
        if (vld(&primary)) {
            uint* bss = &_kbss_start;
            uint* bss_end = &_kbss_end;
            while (bss < bss_end) {
                vst(bss++, 0);
            }

            import kernel.board;
            Uart.setup(115200);
            vst(&primary, 0);
            _cpu[coreid].primary = true;
        } else {
            _cpu[coreid].primary = false;
        }
        memory_fence();

        _cpu[coreid].coreid = coreid;
        _cpu[coreid].stack = stack_start;

        Machine.setup();

        kmain(coreid, heap);
    }

    ubyte* init_tls(int coreid, out uintptr stack_start) {
        pragma(inline, false);
        import arch = kernel.arch;
        import kernel.board;

        uintptr stack_base = cast(uintptr) &_kheap_start;
        stack_start = stack_base + (coreid + 1) * 4096;

        arch.wr_cpu(&_cpu[coreid]);

        return cast(ubyte*) (stack_base + Machine.ncores * 4096);
    }
}
