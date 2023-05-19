module plix.elf;

import plix.arch.vm : Pagetable;
import plix.arch.cache : sync_idmem;
import plix.alloc : kalloc, kfree;
import plix.vm : mappg, ka2pa, Perm;

import sys = plix.sys;

import core.math : max, min;
import builtins : memset, memcpy;

private enum magic = 0x464C457FU; // "\x7ELF" in little endian

private enum Prog {
    load = 1,
    flagexec = 1,
    flagwrite = 2,
    flagread = 4,
}

private struct FileHeader {
    alias uword = ulong;

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

private struct ProgHeader {
    alias uword = ulong;

    uint type;
    uint flags;
    uword offset;
    uword vaddr;
    uword paddr;
    uword filesz;
    uword memsz;
    uword align_;
}

// Load the ELF file starting at 'elfdat' into the pagetable 'pt'. Returns true
// on success, and also sets the program's entrypoint and brk address (the
// first address beyond the highest loadable segment).
bool loadelf(Pagetable* pt, ubyte* elfdat, out uintptr entry, out uintptr brk) {
    FileHeader* elf = cast(FileHeader*) elfdat;

    if (elf.magic != magic)
        return false;

    for (ulong i = 0, off = elf.phoff; i < elf.phnum; i++, off += ProgHeader.sizeof) {
        ProgHeader* ph = cast(ProgHeader*) (elfdat + off);
        if (ph.type != Prog.load || ph.memsz == 0)
            continue;

        if (ph.memsz < ph.filesz)
            return false;
        if (ph.vaddr + ph.memsz < ph.vaddr)
            return false;

        // make sure we map on a page boundary
        size_t pad = ph.vaddr % sys.pagesize;

        uintptr va_start = ph.vaddr - pad;
        size_t sz = max(ph.memsz + pad, cast(ulong) sys.pagesize);
        for (uintptr va = va_start; va < va_start + sz; va += sys.pagesize) {
            // Allocate and map one page at a time. The main reason to do this
            // is so that all pages can be easily freed by a pagetable walk
            // when the process is freed.
            ubyte* mem = kalloc(sys.pagesize).ptr;
            if (!mem) {
                return false;
            }
            memset(mem, 0, pad);
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
            if (!pt.mappg(va, mem, Perm.urwx)) {
                kfree(mem, sys.pagesize);
                return false;
            }

            // Must synchronize the instruction and data caches for this region
            // since it is executable.
            sync_idmem(mem, written);
        }

        brk = max(ph.vaddr + ph.memsz, brk);
    }

    entry = elf.entry;
    return true;
}
