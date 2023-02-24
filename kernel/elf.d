module kernel.elf;

private enum magic = 0x464C457FU; // "\x7ELF" in little endian

private enum Prog {
    load = 1,
    flagexec = 1,
    flagwrite = 2,
    flagread = 4,
}

private struct FileHeader(int W) if (W == 64 || W == 32) {
    static if (W == 64) {
        alias uword = ulong;
    } else {
        alias uword = uint;
    }

    uint magic;
    ubyte width;
    ubyte[11] _elf;
    ushort type;
    ushort machine;
    uint version_;
    uword entry;
    uword phoff;
    uword shoff;
    uint flags;
    ushort ehsize;
    ushort phentsize;
    ushort phnum;
    ushort shentsize;
    ushort shnum;
    ushort shstrndx;
}

private struct ProgHeader(int W) if (W == 64 || W == 32) {
    static if (W == 64) {
        alias uword = ulong;
    } else {
        alias uword = uint;
    }

    uint type;
    static if (W == 64) {
        uint flags;
    }
    uword offset;
    uword vaddr;
    uword paddr;
    uword filesz;
    uword memsz;
    static if (W == 32) {
        uint flags;
    }
    uword align_;
}

private int getwidth(ubyte* elfdat) {
    FileHeader!(32)* elf = cast(FileHeader!(32)*) elfdat;
    if (elf.width == 1) {
        return 32;
    } else if (elf.width == 2) {
        return 64;
    }
    assert(0);
}

import kernel.alloc;
import kernel.arch;
import kernel.vm;
import sys = kernel.sys;
import ulib.memory;

// Should be called with a Checkpoint allocator to ensure segments can be freed.
bool load(int W, A)(Pagetable* pt, immutable ubyte* elfdat, out uintptr entry, out uintptr brk, A* alloc) {
    FileHeader!(W)* elf = cast(FileHeader!(W)*) elfdat;

    if (elf.magic != magic)
        return false;

    for (ulong i = 0, off = elf.phoff; i < elf.phnum; i++, off += ProgHeader!(W).sizeof) {
        ProgHeader!(W)* ph = cast(ProgHeader!(W)*) (elfdat + off);
        if (ph.type != Prog.load || ph.memsz == 0)
            continue;

        if (ph.memsz < ph.filesz)
            return false;
        if (ph.vaddr + ph.memsz < ph.vaddr)
            return false;

        // make sure we map on a page boundary
        size_t pad = ph.vaddr % sys.pagesize;

        // allocate physical space for segment, and copy it in
        import ulib.math : max;
        ubyte[] code = knew_array_custom!(ubyte)(alloc, max(ph.memsz + pad, cast(ulong) sys.pagesize));
        if (!code) {
            return false;
        }
        memcpy(code.ptr + pad, elfdat + ph.offset, ph.filesz);
        memset(code.ptr + pad + ph.filesz, 0, ph.memsz - ph.filesz);

        uintptr pa = ka2pa(cast(uintptr) code.ptr);
        // map newly allocated physical space to base va
        for (uintptr va = ph.vaddr - pad; va < ph.vaddr + ph.memsz; va += sys.pagesize, pa += sys.pagesize) {
            if (!pt.map(va, pa, Pte.Pg.normal, Perm.urwx, alloc)) {
                // segments will be freed by the checkpoint allocator this was called with
                return false;
            }
        }
        import ulib.math : max;
        brk = max(ph.vaddr + ph.memsz, brk);

        import core.sync;
        sync_idmem(code.ptr, code.length);
    }

    entry = elf.entry;
    return true;
}
