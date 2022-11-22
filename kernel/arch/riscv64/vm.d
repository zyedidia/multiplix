module kernel.arch.riscv64.vm;

import bits = ulib.bits;
import kernel.alloc;
import kernel.vm;

enum VmMode {
    off = 0,
    sv39 = 8,
    sv48 = 9,
    sv57 = 10,
    sv64 = 11,
}

struct PteFlags {
    bool valid;
    bool read;
    bool write;
    bool exec;
    bool user;
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

    uintptr u(T)(T val) {
        return cast(uintptr) val;
    }

    @property uintptr pa() {
        return (u(ppn0) << 12) | (u(ppn1) << 21) | (u(ppn2) << 30);
    }

    @property void pa(uintptr pa) {
        ppn0 = cast(ushort) bits.get(pa, 20, 12);
        ppn1 = cast(ushort) bits.get(pa, 29, 21);
        ppn2 = cast(ushort) bits.get(pa, 55, 30);
    }

    @property void flags(PteFlags flags) {
        valid = flags.valid;
        read = flags.read;
        write = flags.write;
        exec = flags.exec;
        user = flags.user;
        accessed = 1;
        dirty = 1;
    }
}

struct Pagetable39 {
    align(4096) Pte39[512] ptes;

    void mapGiga(uintptr va, uintptr pa, PteFlags flags) {
        auto vpn2 = bits.get(va, 38, 30);

        ptes[vpn2].flags = flags;
        ptes[vpn2].pa = pa;
    }

    void mapMega(uintptr va, uintptr pa, PteFlags flags) {
        auto vpn2 = bits.get(va, 38, 30);
        auto vpn1 = bits.get(va, 29, 21);

        PteFlags myflags = {flags.valid, false, false, false, flags.user};
        Pagetable39* l2pt = void;
        if (ptes[vpn2].pa == 0) {
            l2pt = cast(Pagetable39*) kallocpage(Pagetable39.sizeof);
            ptes[vpn2].pa = ka2pa(cast(uintptr) l2pt);
        } else {
            l2pt = cast(Pagetable39*) ptes[vpn2].pa;
        }
        ptes[vpn2].flags = myflags;

        l2pt.ptes[vpn1].flags = flags;
        l2pt.ptes[vpn1].pa = pa;
    }

    void mapPage(uintptr va, uintptr pa, PteFlags flags) {
        auto vpn2 = bits.get(va, 38, 30);
        auto vpn1 = bits.get(va, 29, 21);
        auto vpn0 = bits.get(va, 20, 12);

        PteFlags myflags = {flags.valid, false, false, false, flags.user};
        Pagetable39* l2pt = void;
        if (ptes[vpn2].pa == 0) {
            l2pt = cast(Pagetable39*) kallocpage(Pagetable39.sizeof);
            ptes[vpn2].pa = ka2pa(cast(uintptr) l2pt);
        } else {
            l2pt = cast(Pagetable39*) ptes[vpn2].pa;
        }
        ptes[vpn2].flags = myflags;

        Pagetable39* l3pt = void;
        if (l2pt.ptes[vpn1].pa == 0) {
            l3pt = cast(Pagetable39*) kallocpage(Pagetable39.sizeof);
            l2pt.ptes[vpn1].pa = ka2pa(cast(uintptr) l3pt);
        } else {
            l3pt = cast(Pagetable39*) l2pt.ptes[vpn1].pa;
        }
        l2pt.ptes[vpn1].flags = myflags;

        l3pt.ptes[vpn0].flags = flags;
        l3pt.ptes[vpn0].pa = pa;
    }

    shared uintptr pn() {
        return cast(uintptr)(&ptes[0]) / 4096;
    }

    shared uintptr satp(uint asid) {
        uintptr val = bits.write(pn(), 59, 44, asid);
        return bits.write(val, 63, 60, VmMode.sv39);
    }
}
