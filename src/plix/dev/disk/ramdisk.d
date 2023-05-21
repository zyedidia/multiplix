module plix.dev.disk.ramdisk;

import plix.alloc : kalloc;
import core.math : min;

struct RamDisk {
    ubyte[] disk;
    usize blocksz;

    bool initialize(usize blocksz, usize nblocks) {
        this.blocksz = blocksz;

        disk = kalloc(blocksz * nblocks);
        if (!disk)
            return false;

        return true;
    }

    import builtins : memcpy;

    usize read(usize block, ubyte[] data) {
        usize n = min(disk.length - block * blocksz, data.length);
        memcpy(data.ptr, &disk[block * blocksz], n);
        return n;
    }

    usize write(usize block, ubyte[] data) {
        usize n = min(disk.length - block * blocksz, data.length);
        memcpy(&disk[block * blocksz], data.ptr, n);
        return n;
    }
}
