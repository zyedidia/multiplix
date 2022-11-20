module kernel.arch.riscv64.boot;

import kernel.arch.riscv64;

import sbi = kernel.arch.riscv64.sbi;
import sys = kernel.sys;

import ulib.memory;

// Early pagetable (only maps gigapages since we don't have an allocator yet).
shared Pagetable39 kpagetable;

// The main kernel binary is imported here and will be relocated by boot. We
// could import the kernel elf file instead of the bin file to get debug
// symbols for the kernel, but don't have an elf/dwarf parser yet.
auto kbin = cast(immutable ubyte[]) import("kernel.bin");

extern (C) extern shared char _kentry_pa;

// This is the entrypoint immediately after the bootloader and initial setup
// (bss/stack initialization). We initialize virtual memory using an
// identity-mapped pagetable, load the kernel into a high canonical address,
// and jump to it.
void boot(uint hartid) {
    Pagetable39* kpagetable = cast(Pagetable39*) &kpagetable;
    PteFlags flags = {
        valid: true,
        read: true,
        write: true,
        exec: true,
    };
    for (size_t addr = 0; addr < sys.memsizePhysical; addr += sys.gb!(1)) {
        kpagetable.mapGiga(addr, addr, flags);
        kpagetable.mapGiga(sys.highmemBase + addr, addr, flags);
    }

    fencevma();
    Csr.satp = kpagetable.satp(0);
    fencevma();

    // load the kernel into its phyical entrypoint
    memcpy(cast(void*) &_kentry_pa, kbin.ptr, kbin.length);
    fencei();

    // prepare to enable interrupts (only will be enabled when sstatus it
    // written as well)
    Csr.sie = Csr.sie | (1UL << Sie.seie) | (1UL << Sie.stie) | (1UL << Sie.ssie);

    // jump to the kernel entrypoint's high canonical address
    // we have to load sys.highmemBase into a local due to a bug in LDC:
    // https://github.com/ldc-developers/ldc/issues/4264
    auto highmemBase = sys.highmemBase;
    uintptr main = cast(uintptr)(&_kentry_pa) + highmemBase;
    (cast(void function(uint, uint)) main)(hartid, sbi.Hart.nharts());

    while (1) {}
}

import kernel.init : initBss;

extern (C) {
    // Entrypoint after bootstart.s runs.
    void dstart(uint hartid) {
        initBss();
        boot(hartid);
    }

    void ulib_tx(ubyte b) {}
    void ulib_exit(ubyte code) {}
}
