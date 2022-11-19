module kernel.dstart;

import core.volatile;

import kernel.arch.riscv.start : start;
import kernel.main : kmain;
import sys = ulib.sys;
import ulib.memory;

extern (C) extern __gshared ubyte _kbss_start, _kbss_end;
extern (C) extern __gshared ubyte _tdata_start, _tdata_end;
extern (C) extern __gshared ubyte _tbss_start, _tbss_end;
extern (C) extern __gshared ubyte _kheap_start;

void w_tp(uintptr val) {
    asm {
        "mv tp, %0" : : "r" (val);
    }
}

extern (C) void dstart(uint hartid, uint nharts) {
    memset(&_kbss_start, 0, &_kbss_end - &_kbss_start);

    ubyte* heap_start = &_kheap_start + 4096 * nharts;

    size_t tls_size = &_tbss_end - &_tdata_start;
    ubyte* tls_start = heap_start + tls_size * hartid;
    size_t tdata_size = &_tdata_end - &_tdata_start;
    size_t tbss_size = &_tbss_end - &_tbss_start;
    memcpy(tls_start, &_tdata_start, tdata_size);
    memset(tls_start + tdata_size, 0, tbss_size);

    w_tp(cast(uintptr) tls_start);

    kmain(hartid, nharts, cast(uintptr) heap_start + tls_size * nharts);
    sys.exit(0);
}
