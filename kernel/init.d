module kernel.init;

import ulib.memory;

import kernel.main;

import arch = kernel.arch;

extern (C) {
    extern shared ubyte _kbss_start, _kbss_end;
    extern shared ubyte _tdata_start, _tdata_end;
    extern shared ubyte _tbss_start, _tbss_end;
}

// Initializes the BSS section.
void initBss() {
    memset(cast(ubyte*)&_kbss_start, 0, &_kbss_end - &_kbss_start);
}

// Initializes thread-local storage. Each core gets a separate block of
// thread-local storage that must be initialized when it boots up. Given
// an overall thread-local storage block starting at 'base', this function
// initializes a chunk within it for this particular cpu.
//
// Returns the size of the TLS block used.
size_t initTls(uint cpuid, uintptr base) {
    size_t tlsSize = &_tbss_end - &_tdata_start;
    // calculate the start of the TLS region for this cpu
    ubyte* tlsStart = cast(ubyte*)(base + tlsSize * cpuid);
    size_t tdataSize = &_tdata_end - &_tdata_start;
    size_t tbssSize = &_tbss_end - &_tbss_start;
    // copy the tdata into the tls region
    memcpy(tlsStart, cast(const(ubyte)*)&_tdata_start, tdataSize);
    // zero out the tbss
    memset(tlsStart + tdataSize, 0, tbssSize);

    arch.setTlsBase(tlsStart);

    return tdataSize;
}
