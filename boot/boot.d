module boot;

import core.volatile;
import arch = kernel.arch.riscv;
import ulib.memory;

extern (C) extern __gshared uint _kbss_start, _kbss_end;

__gshared arch.Pagetable39 kernel_pagetable;

auto kbin = cast(immutable ubyte[]) import("kernel.bin");

extern (C) void dstart(uint hartid) {
    uint* bss = &_kbss_start;
    uint* bss_end = &_kbss_end;

    while (bss < bss_end) {
        volatileStore(bss++, 0);
    }

    boot(hartid);
}

enum highmem_base = 0xFFFF_FFC0_0000_0000UL;
extern (C) extern __gshared char kernel_entry_pa;

void flush_dcache() {
    ulong* addr = (cast(ulong*) (0x2010000 + 0x200));
    ulong line = 0x8000_0000;
    ulong end = 0x87FF_FFFF;

    while (line < end) {
        volatileStore(addr, line);
        line += 64;
        arch.fence();
    }
}

// The bootloader occupies the first 4 pages of memory, from 0x8000_0000 to
// 0x8000_4000. It sets up a basic pagetable that identity-maps the first 3GB
// of physical memory to low and high canonical addresses. It also initializes
// timer interrupts with an m-mode interrupt handler, and sets up supervisor
// mode. It copies the kernel binary payload, stored in kbin, to 0x8000_4000
// (the kernel's physical entrypoint), and then uses an 'mret' to jump to
// 0xFFFF_FFC0_8000_4000, the kernel's virtual entrypoint. The mret causes a
// switch to s-mode, and enables the MMU.
void boot(uint hartid) {
    import io = ulib.io;
    io.writeln("hello rvos!");
    import kernel.arch.riscv.sbi;
    io.writeln("hart 0 status: ", Hart.get_status(0), " exists: ", Hart.exists(0));
    io.writeln("hart 1 status: ", Hart.get_status(1), " exists: ", Hart.exists(1));
    io.writeln("hart 2 status: ", Hart.get_status(2), " exists: ", Hart.exists(2));

    // set up kernel pagetable so that
    //  VA (0xFFFF'FFC0'0000'0000,...+PHYSMEM) -> PA (0-PHYSMEM) (high canonical addresses)
    //  VA (0-PHYSMEM) -> PA (0-PHYSMEM)
    import sys = kernel.sys;

    for (size_t addr = 0; addr < sys.addrspace_physical; addr += sys.gb!(1)) {
        kernel_pagetable.map_gigapage(addr, addr);
        kernel_pagetable.map_gigapage(highmem_base + addr, addr);
    }

    arch.fence();

    // install the pagetable in satp
    arch.sfence_vma();
    arch.csr_write!(arch.Csr.satp)(kernel_pagetable.satp(0));
    arch.sfence_vma();

    io.writeln("enabled virtual memory");

    memcpy(&kernel_entry_pa, kbin.ptr, kbin.length);
    // initialize arch and tell it to jump to highmem_base

    // LDC bug: adding a manifest constant to an address doesn't work
    auto highmem_base = highmem_base;
    arch.start(hartid, cast(uintptr)(&kernel_entry_pa) + highmem_base);

    while (1) {
    }
}

extern (C) {
    void ulib_tx(ubyte b) {
        import kernel.arch.riscv.sbi;
        legacy_putchar(b);
    }

    void ulib_exit(ubyte code) {
    }
}
