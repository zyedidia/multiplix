module plix.fs.fs;

import plix.fs.bcache : BSIZE, Buf, bread, brelease, bwrite;
import plix.fs.file : Inode;
import plix.print : println;

enum {
    FSMAGIC = 0x10203040,
    NDIRECT = 12,
    NINDIRECT = (BSIZE / uint.sizeof),
    MAXFILE = NDIRECT + NINDIRECT,
    BPB = BSIZE * 8,             // bitmap bits per block
    IPB = BSIZE / Dinode.sizeof, // inodes per block

    NINODE = 50, // max number of active inodes
}

uint iblock(uint i, Superblock sb) {
    return i / cast(uint) IPB + sb.inodestart;
}

uint bblock(uint b, Superblock sb) {
    return b / BPB + sb.bmapstart;
}

struct Superblock {
    uint magic;        // Must be FSMAGIC
    uint size;         // Size of file system image (blocks)
    uint nblocks;      // Number of data blocks
    uint ninodes;      // Number of inodes.
    uint nlog;         // Number of log blocks
    uint logstart;     // Block number of first log block
    uint inodestart;   // Block number of first inode block
    uint bmapstart;    // Block number of first free map block
}

// On-disk inode representation.
struct Dinode {
    short type;              // File type
    short major;             // Major device number (T_DEVICE only)
    short minor;             // Minor device number (T_DEVICE only)
    short nlink;             // Number of links to inode in file system
    uint size;               // Size of file (bytes)
    uint[NDIRECT+1] addrs;   // Data block addresses
}

void readsb(uint dev, Superblock* sb) {
    import builtins : memmove;
    Buf* bp = bread(dev, 1);
    memmove(sb, &bp.data[0], Superblock.sizeof);
}

__gshared Superblock sb;

void fsinit(uint dev) {
    readsb(dev, &sb);
    if (sb.magic != FSMAGIC) {
        assert(0, "invalid file system");
    }
    // TODO: initlog
}

void bzero(uint dev, uint bno) {
    import builtins : memset;
    Buf* bp = bread(dev, bno);
    memset(&bp.data[0], 0, BSIZE);
    // TODO: log_write
    brelease(bp);
}

uint balloc(uint dev) {
    for (int b = 0; b < sb.size; b += BPB) {
        Buf* bp = bread(dev, bblock(b, sb));
        for (uint bi = 0; bi < BPB && b + bi < sb.size; bi++) {
            int m = 1 << (bi % 8);
            if ((bp.data[bi / 8] & m) == 0) {
                bp.data[bi / 8] |= m;
                brelease(bp);
                bzero(dev, b + bi);
                return b + bi;
            }
        }
        brelease(bp);
    }
    println("balloc: out of blocks");
    return 0;
}

void bfree(uint dev, uint b) {
    Buf* bp = bread(dev, bblock(b, sb));
    int bi = b % BPB;
    int m = 1 << (bi % 8);
    if ((bp.data[bi / 8] & m) == 0) {
        assert(0, "freeing free block");
    }
    bp.data[bi / 8] &= ~m;
    // TODO: log_write
    brelease(bp);
}

// string skipelem(string path, string name) {
// }
