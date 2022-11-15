module boot;

import core.volatile;
import arch = kernel.arch.riscv;
import ulib.memory;

extern (C) extern __gshared uint _kbss_start, _kbss_end;

__gshared arch.Pagetable39 kernel_pagetable;

__gshared auto kernelbin = cast(ubyte[]) import("kernel.bin");

extern (C) void dstart() {
    uint* bss = &_kbss_start;
    uint* bss_end = &_kbss_end;

    while (bss < bss_end) {
        volatileStore(bss++, 0);
    }

    boot();
}

enum highmem_base = 0xFFFF_FFC0_0000_0000;
enum kernel_entry = 0xFFFF_FFC0_8000_8000;

void boot() {
    // set up kernel pagetable so that
    //  VA (0xFFFF'FFC0'0000'0000,...+PHYSMEM) -> PA (0-PHYSMEM) (high canonical addresses)
    //  VA (0-PHYSMEM) -> PA (0-PHYSMEM)

    enum gb(ulong n) = 1024 * 1024 * 1024 * n;
    kernel_pagetable.map_gigapage(gb!(0), gb!(0));
    kernel_pagetable.map_gigapage(gb!(1), gb!(1));
    kernel_pagetable.map_gigapage(gb!(2), gb!(2));
    kernel_pagetable.map_gigapage(highmem_base + gb!(0), gb!(0));
    kernel_pagetable.map_gigapage(highmem_base + gb!(1), gb!(1));
    kernel_pagetable.map_gigapage(highmem_base + gb!(2), gb!(2));

    arch.csr_write_bits!(arch.Csr.satp)(43, 0, kernel_pagetable.pn());
    arch.csr_write_bits!(arch.Csr.satp)(59, 44, 0);
    arch.csr_write_bits!(arch.Csr.satp)(63, 60, arch.Satp.sv39);

    // load the bin file in kernelbin into 0xFFFF'FFC0'8000'8000 (physical address 0x8000'8000)
    // TODO: manual loop doesn't work at O2 or O3?
    /* for (int i = 0; i < kernelbin.length; i++) { */
    /*     volatileStore(cast(ubyte*) 0x8000_8000 + i, volatileLoad(&kernelbin[i])); */
    /* } */
    memcpy(cast(void*) 0x8000_8000, kernelbin.ptr, kernelbin.length);
    // initialize arch and tell it to jump to highmem_base
    arch.start(cast(uintptr) kernel_entry);

    while (1) {}
}

extern (C) {
    void ulib_tx(ubyte b) {}
    void ulib_exit(ubyte code) {}
}
