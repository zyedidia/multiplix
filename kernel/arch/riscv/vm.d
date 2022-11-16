module kernel.arch.riscv.vm;

import kernel.arch.riscv.csr;

import bits = ulib.bits;

struct Pte39 {
    ulong data;
    mixin(bits.field!(data,
        "valid",      1,
        "read",       1,
        "write",      1,
        "exec",       1,
        "user",       1,
        "global",     1,
        "accessed",   1,
        "dirty",      1,
        "rsw",        2,
        "ppn0",       9,
        "ppn1",       9,
        "ppn2",       26,
        "_reserved",  10,
    ));
}

struct Pagetable39 {
    align(4096)
    Pte39[512] ptes;

    void map_gigapage(uintptr va, uintptr pa) {
        auto vpn2 = bits.get(va, 38, 30);
        auto ppn2 = bits.get(pa, 55, 30);

        ptes[vpn2].valid = 1;
        ptes[vpn2].read = 1;
        ptes[vpn2].write = 1;
        ptes[vpn2].exec = 1;
        ptes[vpn2].ppn0 = 0; // ignored
        ptes[vpn2].ppn1 = 0; // ignored
        ptes[vpn2].ppn2 = cast(uint) ppn2;
    }

    void map_megapage(uintptr va, uintptr pa) {
        // TODO
    }

    void map_page(uintptr va, uintptr pa) {
        // TODO
    }

    uintptr pn() {
        return cast(uintptr) (&ptes[0]) / 4096;
    }

    uintptr satp(uint asid) {
        uintptr val = bits.set(pn(), 59, 44, asid);
        return bits.set(val, 63, 60, Satp.sv39);
    }
}
