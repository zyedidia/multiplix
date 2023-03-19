module kernel.arch.riscv64.vm;

import libc;
import ulib.option;
import bits = ulib.bits;

import kernel.alloc;
import kernel.vm;

import sys = kernel.sys;

private enum VmMode {
    off = 0,
    sv39 = 8,
    sv48 = 9,
    sv57 = 10,
    sv64 = 11,
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
        "cow",        1,
        "rsw",        1,
        "ppn0",       9,
        "ppn1",       9,
        "ppn2",       26,
        "_reserved",  10,
    ));
    // dfmt on

    private uintptr u(T)(T val) {
        return cast(uintptr) val;
    }

    // set this pte to valid
    void validate() {
        valid = 1;
        accessed = 1;
        dirty = 1;
    }

    uintptr pa() {
        return (u(ppn0) << 12) | (u(ppn1) << 21) | (u(ppn2) << 30);
    }

    void pa(uintptr pa) {
        data = bits.write(data, 53, 10, bits.get(pa, 55, 12));
    }

    bool leaf(int level) {
        // true if at least one of read/write/exec is 1
        return bits.get(data, 3, 1) != 0;
    }

    void perm(Perm perm) {
        read = (perm & Perm.r) != 0;
        write = (perm & Perm.w) != 0;
        exec = (perm & Perm.x) != 0;
        user = (perm & Perm.u) != 0;
        cow = (perm & Perm.cow) != 0;
    }

    Perm perm() {
        Perm p;
        if (read)
            p |= Perm.r;
        if (write)
            p |= Perm.w;
        if (exec)
            p |= Perm.x;
        if (user)
            p |= Perm.u;
        if (cow)
            p |= Perm.cow;
        return p;
    }

    enum Pg {
        normal = 0, // sv39 normal page: 4K
        mega   = 1, // sv39 mega page: 2M
        giga   = 2, // sv39 giga page: 1G

        min = normal,
        max = giga,
    }

    static Pg down(Pg type) {
        assert(type != Pg.min);
        return cast(Pg) (cast(int) type - 1);
    }
}

private uintptr vpn(uint level, uintptr va) {
    return (va >> 12 + 9 * level) & bits.mask!uintptr(9);
}

struct Pagetable {
    align(4096) Pte[512] ptes;

    // Lookup the pte corresponding to 'va'. Stops after the corresponding
    // level. If 'alloc' is true, allocates new pagetables as necessary using
    // the specified allocator.
    Pte* walk(A, bool alloc)(uintptr va, ref Pte.Pg endlevel, A* allocator) {
        Pagetable* pt = &this;

        for (Pte.Pg level = Pte.Pg.max; level > endlevel; level = Pte.down(level)) {
            Pte* pte = &pt.ptes[vpn(level, va)];
            if (pte.leaf(level)) {
                endlevel = level;
                return pte;
            } else if (pte.valid) {
                pt = cast(Pagetable*) pa2kpa(pte.pa);
            } else {
                static if (!alloc) {
                    endlevel = level;
                    return null;
                } else {
                    pt = knew_custom!(Pagetable)(allocator);
                    if (!pt) {
                        endlevel = level;
                        return null;
                    }
                    memset(pt, 0, Pagetable.sizeof);
                    pte.pa = ka2pa(cast(uintptr) pt);
                    pte.valid = 1;
                }
            }
        }
        return &pt.ptes[vpn(endlevel, va)];
    }

    Pte* walk(uintptr va, ref Pte.Pg endlevel) {
        return walk!(void, false)(va, endlevel, null);
    }

    // Recursively free all pagetable pages.
    void free(Pte.Pg level = Pte.Pg.max) {
        for (int i = 0; i < ptes.length; i++) {
            Pte* pte = &ptes[i];
            if (pte.valid && pte.leaf(level)) {
                pte.data = 0;
            } else if (pte.valid) {
                Pagetable* child = cast(Pagetable*) pa2kpa(pte.pa);
                child.free(Pte.down(level));
                pte.data = 0;
            }
        }
        kfree(&this);
    }

    // Map 'va' to 'pa' with the given page size and permissions. Returns false
    // if allocation failed.
    bool map(A)(uintptr va, uintptr pa, Pte.Pg pgtyp, Perm perm, A* allocator) {
        Pte* pte = walk!(A, true)(va, pgtyp, allocator);
        if (!pte) {
            return false;
        }
        pte.pa = pa;
        pte.perm = perm;
        pte.validate();
        return true;
    }

    // Simple giga-page mapper. This is equivalent to map(va, pa, Pte.Pg.giga,
    // perm) but does not use any allocation functions so it can be used easily
    // in the early boot process.
    void map_giga(uintptr va, uintptr pa, Perm perm) {
        auto vpn = vpn(2, va);
        ptes[vpn].perm = perm;
        ptes[vpn].pa = pa;
        ptes[vpn].validate();
    }

    // Return this pagetable's physical page number.
    private uintptr pn() {
        return kpa2pa(cast(uintptr)(&ptes[0])) / sys.pagesize;
    }

    // Return the bits to needed to set satp to this pagetable, given an ASID.
    uintptr satp(uint asid) {
        uintptr val = bits.write(pn(), 59, 44, asid);
        return bits.write(val, 63, 60, VmMode.sv39);
    }

    // Converts a level type to the size of the region that the level maps.
    static size_t level2size(Pte.Pg type) {
        final switch (type) {
            case Pte.Pg.normal: return 4096;
            case Pte.Pg.mega: return sys.mb!(2);
            case Pte.Pg.giga: return sys.gb!(1);
        }
    }
}

Pagetable* current_pt() {
    import kernel.arch.riscv64.csr;
    return cast(Pagetable*) pa2kpa(((Csr.satp & 0xfffffffffffUL) << 12));
}

void kernel_ptswitch(Pagetable* pt) {
    import kernel.arch.riscv64.csr;
    import core.sync;
    Csr.satp = pt.satp(0);
    vm_fence();
}
