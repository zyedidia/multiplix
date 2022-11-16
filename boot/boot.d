module boot;

import core.volatile;
import arch = kernel.arch.riscv;
import ulib.memory;

extern (C) extern __gshared uint _kbss_start, _kbss_end;

__gshared arch.Pagetable39 kernel_pagetable;

auto kbin = cast(immutable ubyte[]) import("kernel.bin");

extern (C) void dstart() {
    uint* bss = &_kbss_start;
    uint* bss_end = &_kbss_end;

    while (bss < bss_end) {
        volatileStore(bss++, 0);
    }

    boot();
}

enum highmem_base = 0xFFFF_FFC0_0000_0000UL;
extern (C) extern __gshared char kernel_entry_pa;

// The bootloader occupies the first 4 pages of memory, from 0x8000_0000 to
// 0x8000_4000. It sets up a basic pagetable that identity-maps the first 3GB
// of physical memory to low and high canonical addresses. It also initializes
// timer interrupts with an m-mode interrupt handler, and sets up supervisor
// mode. It copies the kernel binary payload, stored in kbin, to 0x8000_4000
// (the kernel's physical entrypoint), and then uses an 'mret' to jump to
// 0xFFFF_FFC0_8000_4000, the kernel's virtual entrypoint. The mret causes a
// switch to s-mode, and enables the MMU.
void boot() {
    // set up kernel pagetable so that
    //  VA (0xFFFF'FFC0'0000'0000,...+3GB) -> PA (0-3GB) (high canonical addresses)
    //  VA (0-PHYSMEM) -> PA (0-3GB)

    import sys = kernel.sys;

    for (size_t addr = 0; addr < sys.memsize_physical; addr += sys.gb!(1)) {
        kernel_pagetable.map_gigapage(addr, addr);
        kernel_pagetable.map_gigapage(highmem_base + addr, addr);
    }

    // install the pagetable in satp
    arch.csr_write!(arch.Csr.satp)(kernel_pagetable.satp(0));

    memcpy(&kernel_entry_pa, kbin.ptr, kbin.length);
    // initialize arch and tell it to jump to highmem_base

    // LDC bug: adding a manifest constant to an address doesn't work
    auto highmem_base = highmem_base;
    arch.start(cast(uintptr) (&kernel_entry_pa) + highmem_base);

    while (1) {}
}

extern (C) {
    // stub implementations of ulib functions so that we can link with ulib
    void ulib_tx(ubyte b) {}
    void ulib_exit(ubyte code) {}
}
