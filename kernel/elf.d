module kernel.elf;

import core.sync;

import kernel.alloc;
import kernel.board;
import kernel.arch;

import sys = kernel.sys;
import vm = kernel.vm;

import ulib.memory;

enum magic = 0x464C457FU; // "\x7ELF" in little endian

enum Prog {
    load = 1,
    flagexec = 1,
    flagwrite = 2,
    flagread = 4,
}

struct FileHeader(int W) if (W == 64 || W == 32) {
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

struct ProgHeader(int W) if (W == 64 || W == 32) {
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

int getwidth(ubyte* elfdat) {
    FileHeader!(32)* elf = cast(FileHeader!(32)*) elfdat;
    if (elf.width == 1) {
        return 32;
    } else if (elf.width == 2) {
        return 64;
    }
    assert(0);
}

uintptr load(int W, A)(Pagetable* pt, immutable ubyte* elfdat, out uintptr entry, A* alloc) {
    FileHeader!(W)* elf = cast(FileHeader!(W)*) elfdat;

    assert(elf.magic == magic);

    uintptr brk;

    for (ulong i = 0, off = elf.phoff; i < elf.phnum; i++, off += ProgHeader!(W).sizeof) {
        ProgHeader!(W)* ph = cast(ProgHeader!(W)*) (elfdat + off);
        if (ph.type != Prog.load) {
            continue;
        }
        if (ph.memsz == 0) {
            continue;
        }

        // TODO: these shouldn't be assertions
        assert(ph.memsz >= ph.filesz);
        assert(ph.vaddr + ph.memsz >= ph.vaddr);

        // make sure we map on a page boundary
        size_t pad = ph.vaddr % sys.pagesize;

        // allocate physical space for segment, and copy it in
        import ulib.math : max;
        ubyte[] code = knew_array_custom!(ubyte)(alloc, max(ph.memsz + pad, cast(ulong) sys.pagesize));
        if (!code) {
            return 0;
        }
        memcpy(code.ptr + pad, elfdat + ph.offset, ph.filesz);
        memset(code.ptr + pad + ph.filesz, 0, ph.memsz - ph.filesz);

        // map newly allocated physical space to base va
        for (uintptr va = ph.vaddr - pad, pa = vm.ka2pa(cast(uintptr) code.ptr); va < ph.vaddr + ph.memsz; va += sys.pagesize, pa += sys.pagesize) {
            if (!pt.map(va, pa, Pte.Pg.normal, Perm.urwx, alloc)) {
                // memory will be freed by caller via checkpoint free (in proc creation)
                return 0;
            }
        }

        import ulib.math : max;
        brk = max(ph.vaddr + ph.memsz, brk);

        sync_idmem(code.ptr, code.length);
    }

    entry = elf.entry;
    return brk;
}
