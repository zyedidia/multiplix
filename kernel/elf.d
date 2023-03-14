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
import libc;

// Load the ELF file starting at 'elfdat' into the pagetable 'pt'. Returns true
// on success, and also sets the program's entrypoint and brk address (the
// first address beyond the highest loadable segment).
bool load(int W)(Pagetable* pt, ubyte* elfdat, out uintptr entry, out uintptr brk) {
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

        import ulib.math : max, min;
        uintptr va_start = ph.vaddr - pad;
        size_t sz = max(ph.memsz + pad, cast(ulong) sys.pagesize);
        for (uintptr va = va_start; va < va_start + sz; va += sys.pagesize) {
            // Allocate and map one page at a time. The main reason to do this
            // is so that all pages can be easily freed by a pagetable walk
            // when the process is freed.
            ubyte* mem = cast(ubyte*) kalloc(sys.pagesize);
            if (!mem) {
                return false;
            }
            memset(mem, 0, pad);
            mem += pad;
            size_t written = pad;
            pad = 0;
            size_t soff = va - ph.vaddr;
            if (ph.filesz > soff) {
                // Haven't yet reached ph.filesz, so there is more data from
                // the ELF file to copy in.
                size_t n = min(sys.pagesize - written, ph.filesz - soff);
                memcpy(mem + written, elfdat + ph.offset + soff, n);
                written += n;
            }
            // Set the rest of the data to 0.
            memset(mem + written, 0, sys.pagesize - written);
            if (!pt.mappg(va, ka2pa(cast(uintptr) mem), Perm.urwx)) {
                kfree(mem);
                return false;
            }

            // Must synchronize the instruction and data caches for this region
            // since it is executable.
            import core.sync;
            sync_idmem(mem, written);
        }

        import ulib.math : max;
        brk = max(ph.vaddr + ph.memsz, brk);
    }

    entry = elf.entry;
    return true;
}
