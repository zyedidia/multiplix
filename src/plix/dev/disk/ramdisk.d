module plix.dev.disk.ramdisk;

import plix.alloc : kalloc;
import core.math : min;

import plix.fs.bcache : Buf;

import builtins : memcpy;

version (kernel) {
    private __gshared ubyte[] disk = cast(ubyte[]) import("fs.img");
} else {
    private __gshared ubyte[] disk;
}

enum blocksz = 1024;

struct RamDisk {
    static usize read(Buf* b) {
        usize n = min(disk.length - b.blocknum * blocksz, b.data.length);
        memcpy(b.data.ptr, &disk[b.blocknum * blocksz], n);
        return n;
    }

    static usize write(Buf* b) {
        usize n = min(disk.length - b.blocknum * blocksz, b.data.length);
        memcpy(&disk[b.blocknum * blocksz], b.data.ptr, n);
        return n;
    }
}
