module kernel.cpu;

import arch = kernel.arch;

import kernel.board;

struct Cpu {
    int coreid;
}

Cpu cpuinfo = Cpu(42);

extern (C) {
    extern __gshared ubyte _kheap_start;
    extern __gshared ubyte _tdata_start, _tdata_end;
    extern __gshared ubyte _tbss_start, _tbss_end;
}

// Returns the location and size of this core's TLS region.
ubyte* tls_region(out size_t size) {
    uintptr stack_base = cast(uintptr) &_kheap_start;
    uintptr tls_base = stack_base + System.ncores * 4096;
    size_t tls_size = (&_tbss_end - &_tdata_start) + arch.tcb_size;
    size = tls_size;
    return cast(ubyte*) (tls_base + tls_size * cpuinfo.coreid);
}
