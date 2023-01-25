module kernel.arch.riscv64.vm;

import ulib.memory;
import ulib.option;
import bits = ulib.bits;

import kernel.alloc;
import kernel.vm;

import sys = kernel.sys;

enum VmMode {
    off = 0,
    sv39 = 8,
    sv48 = 9,
    sv57 = 10,
    sv64 = 11,
}

struct Perm {
    enum Bits {
        valid = 0,
        read = 1,
        write = 2,
        exec = 3,
        user = 4,
        global = 5,
        accessed = 6,
        dirty = 7,
    }

    enum v = (1 << Bits.valid);
    enum ad = (1 << Bits.accessed) | (1 << Bits.dirty);
    // kernel read/write/exec
    enum krwx = ad | v | (1 << Bits.read) | (1 << Bits.write) | (1 << Bits.exec);
    // user read/write/exec
    enum urwx = krwx | (1 << Bits.user);
}

struct Pte {
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

    uintptr pa() {
        return (u(ppn0) << 12) | (u(ppn1) << 21) | (u(ppn2) << 30);
    }

    void pa(uintptr pa) {
        data = bits.write(data, 53, 10, bits.get(pa, 55, 12));
    }

    void perm(uint perm) {
        data = bits.write(data, 7, 0, perm);
    }

    bool leaf(int level) {
        // true if at least one of read/write/exec is 1
        return bits.get(data, 3, 1) != 0;
    }

    enum Pg {
        normal = 0, // sv39 normal page: 4K
        mega = 1, // sv39 mega page: 2M
        giga = 2, // sv39 giga page: 1G

        min = normal,
        max = giga,
    }

    static Pg down(Pg type) {
        assert(type != Pg.min);
        return cast(Pg) (cast(int) type - 1);
    }
}

private uintptr vpn(uint level, uintptr va) {
    return (va >> 12+9*level) & bits.mask!uintptr(9);
}

struct Pagetable {
    align(4096) Pte[512] ptes;

    // Lookup the pte corresponding to 'va'. Stops after the corresponding
    // level. If 'alloc' is true, allocates new pagetables as necessary.
    Opt!(Pte*) walk(A, bool alloc)(uintptr va, ref Pte.Pg endlevel, A* allocator) {
        Pagetable* pt = &this;

        for (Pte.Pg level = Pte.Pg.max; level > endlevel; level = Pte.down(level)) {
            Pte* pte = &pt.ptes[vpn(level, va)];
            if (pte.leaf(level)) {
                endlevel = level;
                return Opt!(Pte*)(pte);
            } else if (pte.valid) {
                pt = cast(Pagetable*) pa2ka(pte.pa);
            } else {
                static if (!alloc) {
                    endlevel = level;
                    return Opt!(Pte*).none;
                } else {
                    auto pg = kalloc_block(allocator, Pagetable.sizeof);
                    if (!pg.has()) {
                        endlevel = level;
                        return Opt!(Pte*).none;
                    }
                    pt = cast(Pagetable*) pg.get();
                    memset(pt, 0, Pagetable.sizeof);
                    pte.pa = ka2pa(cast(uintptr) pt);
                    pte.valid = 1;
                }
            }
        }
        return Opt!(Pte*)(&pt.ptes[vpn(endlevel, va)]);
    }

    Opt!(Pte*) walk(uintptr va, ref Pte.Pg endlevel) {
        return walk!(void, false)(va, endlevel, null);
    }

    // Map 'va' to 'pa' with the given page size and permissions. Returns false
    // if allocation failed.
    bool map(A)(uintptr va, uintptr pa, Pte.Pg pgtyp, uint perm, A* allocator) {
        auto opte = walk!(A, true)(va, pgtyp, allocator);
        if (!opte.has()) {
            return false;
        }
        auto pte = opte.get();
        pte.pa = pa;
        pte.perm = perm;
        return true;
    }

    // Simple giga-page mapper. This is equivalent to map(va, pa,
    // Pte.Pg.giga, perm) but does not use any allocation functions so it can
    // be used in the early boot process.
    void map_giga(uintptr va, uintptr pa, uint perm) {
        auto vpn = vpn(2, va);
        ptes[vpn].perm = perm;
        ptes[vpn].pa = pa;
    }

    // Return this pagetable's pagenumber.
    uintptr pn() {
        return kpa2pa(cast(uintptr)(&ptes[0])) / sys.pagesize;
    }

    // Return the bits to needed to set satp to this pagetable, given an ASID.
    uintptr satp(uint asid) {
        uintptr val = bits.write(pn(), 59, 44, asid);
        return bits.write(val, 63, 60, VmMode.sv39);
    }

    static size_t level2size(Pte.Pg type) {
        size_t size = void;
        final switch (type) {
            case Pte.Pg.normal: return 4096;
            case Pte.Pg.mega: return sys.mb!(2);
            case Pte.Pg.giga: return sys.gb!(1);
        }
    }
}
