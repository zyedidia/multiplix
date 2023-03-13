module kernel.dstart;

import core.volatile;

import kernel.cpu;

import libc;

extern (C) {
    extern __gshared uint _kbss_start, _kbss_end;
    extern __gshared ubyte _kheap_start;

    void kmain(int coreid, ubyte* heap);

    version (GNU) {
        import gcc.attributes;
        @no_sanitize("kernel-address", "undefined") {
            private void init_bss();
            private ubyte* init_tls(int coreid, out uintptr stack_start);
            void dstart(int coreid, bool primary);
        }
    }

    void dstart(int coreid, bool primary) {
        import kernel.board;
        import core.sync;

        uintptr stack_start;
        ubyte* heap = init_tls(coreid, stack_start);
        compiler_fence();

        if (primary) {
            init_bss();
            memory_fence();
            Uart.setup(115200);
        }
        memory_fence();

        _cpu[coreid].primary = primary;
        _cpu[coreid].coreid = coreid;
        _cpu[coreid].stack = stack_start;

        compiler_fence();

        Machine.setup();

        kmain(coreid, heap);
    }

    private void init_bss() {
        uint* bss = &_kbss_start;
        uint* bss_end = &_kbss_end;
        while (bss < bss_end) {
            vst(bss++, 0);
        }
    }

    private ubyte* init_tls(int coreid, out uintptr stack_start) {
        import arch = kernel.arch;
        import kernel.board;

        uintptr stack_base = cast(uintptr) &_kheap_start;
        stack_start = stack_base + (coreid + 1) * 4096;

        arch.wr_cpu(&_cpu[coreid]);

        return cast(ubyte*) (stack_base + Machine.ncores * 4096);
    }
}
