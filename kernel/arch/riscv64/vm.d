module kernel.arch.riscv64.vm;

import bits = ulib.bits;

enum VmMode {
    off = 0,
    sv39 = 8,
    sv48 = 9,
    sv57 = 10,
    sv64 = 11,
}

struct Pte39 {
    ulong data;
    // dfmt off
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
    // dfmt on
}

struct PteFlags {
    bool valid;
    bool read;
    bool write;
    bool exec;
    bool user;
}

struct Pagetable39 {
    align(4096) Pte39[512] ptes;

    void mapGiga(uintptr va, uintptr pa, PteFlags flags) {
        auto vpn2 = bits.get(va, 38, 30);
        auto ppn2 = bits.get(pa, 55, 30);

        ptes[vpn2].valid = flags.valid;
        ptes[vpn2].read = flags.read;
        ptes[vpn2].write = flags.write;
        ptes[vpn2].exec = flags.exec;
        ptes[vpn2].user = flags.user;
        ptes[vpn2].accessed = 1;
        ptes[vpn2].dirty = 1;
        ptes[vpn2].ppn0 = 0; // ignored
        ptes[vpn2].ppn1 = 0; // ignored
        ptes[vpn2].ppn2 = cast(uint) ppn2;
    }

    void mapMega(uintptr va, uintptr pa, PteFlags flags) {
        // TODO
    }

    void mapPage(uintptr va, uintptr pa, PteFlags flags) {
        // TODO
    }

    shared uintptr pn() {
        return cast(uintptr)(&ptes[0]) / 4096;
    }

    shared uintptr satp(uint asid) {
        uintptr val = bits.write(pn(), 59, 44, asid);
        return bits.write(val, 63, 60, VmMode.sv39);
    }
}
