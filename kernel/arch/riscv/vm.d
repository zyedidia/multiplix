module kernel.arch.riscv.vm;

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
        auto vpn = bits.get(va, 38, 30);
        auto ppn2 = bits.get(pa, 55, 30);

        ptes[vpn].valid = 1;
        ptes[vpn].read = 1;
        ptes[vpn].write = 1;
        ptes[vpn].exec = 1;
        ptes[vpn].ppn0 = 0; // ignored
        ptes[vpn].ppn1 = 0; // ignored
        ptes[vpn].ppn2 = cast(uint) ppn2;
    }

    uintptr pn() {
        return cast(uintptr) (&ptes[0]) / 4096;
    }
}
