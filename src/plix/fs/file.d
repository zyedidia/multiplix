module plix.fs.file;

import plix.fs.fs;
import plix.fs.bcache;
import plix.fs.stat;
import plix.fs.stat : Stat;
import plix.fs.dir : Dirent, namecmp;

import plix.pipe;

import core.math : min;

import plix.print;

import builtins : memmove, memset;

enum Ft {
    NONE,
    PIPE,
    INODE,
    DEVICE,
}

struct File {
    Ft type;
    int refcnt;
    bool readable;
    bool writable;
    Pipe* pipe;
    Inode* ip;
    uint off;
    short major;

    // Increment ref count for file f.
    File* dup() {
        assert(refcnt >= 1);
        refcnt++;
        return &this;
    }

    void close() {
        assert(refcnt >= 1);
        refcnt--;
        if (refcnt > 0) {
            return;
        }

        File ff = this;
        refcnt = 0;
        type = Ft.NONE;

        if (ff.type == Ft.PIPE) {
            // TODO: pipeclose
        } else if (ff.type == Ft.INODE || ff.type == Ft.DEVICE) {
            ff.ip.put();
        }
    }

    int stat(uintptr addr) {
        if (type == Ft.INODE || type == Ft.DEVICE) {
            ip.lock();
            Stat* st = cast(Stat*) addr;
            ip.stat(st);
            ip.unlock();
            return 0;
        }
        return -1;
    }

    // file read
    int read(uintptr addr, int n) {
        if (!readable)
            return -1;

        int r;
        if (type == Ft.PIPE) {
            // TODO: piperead
        } else if (type == Ft.DEVICE) {
            // TODO: more general device read
            ubyte[] buf = (cast(ubyte*) addr)[0 .. n];
            import plix.board;
            for (int i = 0; i < n; i++) {
                buf[i] = uart.rx();
            }
        } else if (type == Ft.INODE) {
            ip.lock();
            if ((r = ip.read(cast(ubyte*) addr, off, n)) > 0)
                off += r;
            ip.unlock();
        } else {
            assert(0);
        }

        return r;
    }

    // file write
    int write(ulong addr, int n) {
        if (!writable)
            return -1;

        int r, ret;
        if (type == Ft.PIPE) {
            // TODO: pipewrite
        } else if (type == Ft.DEVICE) {
            // TODO: we are just writing to the UART instead of the selected device
            string buf = cast(string) (cast(ubyte*) addr)[0 .. n];
            print(buf);
            ret = n;
        } else if (type == Ft.INODE) {
            int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
            int i = 0;
            while (i < n) {
                int n1 = n - i;
                if (n1 > max)
                    n1 = max;

                ip.lock();
                if ((r = ip.write(cast(ubyte*) addr + i, off, n1)) > 0)
                    off += r;
                ip.unlock();

                if (r != n1) {
                    break;
                }
                i += r;
            }
            ret = (i == n ? n : -1);
        } else {
            assert(0);
        }

        return ret;
    }
}

// Max number of open files
enum NFILE = 128;

private __gshared File[NFILE] files;

void finit() {
}

File* falloc() {
    for (usize i = 0; i < files.length; i++) {
        File* f = &files[i];
        if (f.refcnt == 0) {
            f.refcnt = 1;
            return f;
        }
    }
    return null;
}

// In-memory inode representation
struct Inode {
    uint dev;           // Device number
    uint inum;          // Inode number
    int refcnt;         // Reference count
    int valid;          // inode has been read from disk?

    short type;         // copy of disk inode
    short major;
    short minor;
    short nlink;
    uint size;
    uint[NDIRECT+1] addrs;

    // copy a modified in-memory inode to disk
    void update() {
        Buf* bp = bread(dev, iblock(inum, sb));
        Dinode* dip = cast(Dinode*) bp.data.ptr + inum % IPB;
        dip.type = type;
        dip.major = major;
        dip.minor = minor;
        dip.nlink = nlink;
        dip.size = size;
        memmove(dip.addrs.ptr, addrs.ptr, addrs.sizeof);
        brelease(bp);
    }

    Inode* dup() {
        refcnt++;
        return &this;
    }

    void lock() {
        assert(refcnt >= 1);

        if (!valid) {
            Buf* bp = bread(dev, iblock(inum, sb));
            Dinode* dip = cast(Dinode*) bp.data.ptr + inum % IPB;
            type = dip.type;
            major = dip.major;
            minor = dip.minor;
            nlink = dip.nlink;
            size = dip.size;
            memmove(addrs.ptr, dip.addrs.ptr, addrs.sizeof);
            brelease(bp);
            valid = true;
            assert(type != 0);
        }
    }

    void unlock() {
        assert(refcnt >= 1);
    }

    void put() {
        if (refcnt == 1 && valid && nlink == 0) {
            // inode has no links and no other references: truncate and free
            trunc();
            type = 0;
            update();
            valid = false;
        }
        refcnt--;
    }

    void unlockput() {
        unlock();
        put();
    }

    // Return the disk block address of the nth block in the inode.
    uint bmap(uint bn) {
        uint addr;
        Buf* bp;

        if (bn < NDIRECT) {
            if ((addr = addrs[bn]) == 0) {
                addr = balloc(dev);
                if (!addr)
                    return 0;
                addrs[bn] = addr;
            }
            return addr;
        }
        bn -= NDIRECT;

        if (bn < NINDIRECT) {
            // load indirect block, allocating if necessary
            if ((addr = addrs[NDIRECT]) == 0) {
                addr = balloc(dev);
                if (!addr)
                    return 0;
                addrs[NDIRECT] = addr;
            }
            bp = bread(dev, addr);
            uint* a = cast(uint*) bp.data.ptr;
            if ((addr = a[bn]) == 0) {
                addr = balloc(dev);
                if (addr) {
                    a[bn] = addr;
                }
            }
            brelease(bp);
            return addr;
        }
        assert(0, "bmap: out of range");
    }

    void trunc() {
        for (int i = 0; i < NDIRECT; i++) {
            if (addrs[i]) {
                bfree(dev, addrs[i]);
                addrs[i] = 0;
            }
        }

        if (addrs[NDIRECT]) {
            Buf* bp = bread(dev, addrs[NDIRECT]);
            uint* a = cast(uint*) bp.data.ptr;
            for (int j = 0; j < NINDIRECT; j++) {
                if (a[j])
                    bfree(dev, a[j]);
            }
            brelease(bp);
            bfree(dev, addrs[NDIRECT]);
            addrs[NDIRECT] = 0;
        }
        size = 0;
        update();
    }

    void stat(Stat* st) {
        st.dev = dev;
        st.ino = inum;
        st.type = type;
        st.nlink = nlink;
        st.size = size;
    }

    int read(ubyte* dst, uint off, uint n) {
        if (off > size || off + n < off)
            return 0;
        if (off + n > size)
            n = size - off;

        uint m, tot;
        for (tot = 0; tot < n; tot += m, off += m, dst += m) {
            uint addr = bmap(off / BSIZE);
            if (!addr)
                break;
            Buf* bp = bread(dev, addr);
            m = min(n - tot, BSIZE - off%BSIZE);
            memmove(dst, bp.data.ptr + (off % BSIZE), m);
            brelease(bp);
        }
        return tot;
    }

    int write(ubyte* src, uint off, uint n) {
        if (off > size || off + n < off) {
            return -1;
        }
        if (off + n > MAXFILE * BSIZE) {
            return -1;
        }

        uint tot, m;
        for (tot = 0; tot < n; tot += m, off += m, src += m) {
            uint addr = bmap(off / BSIZE);
            if (!addr)
                break;
            Buf* bp = bread(dev, addr);
            m = min(n - tot, BSIZE - off % BSIZE);
            memmove(bp.data.ptr + (off % BSIZE), src, m);
            brelease(bp);
        }

        if (off > size)
            size = off;

        update();

        return tot;
    }

    // Directory operations

    // Look for a directory entry in a directory.
    Inode* lookup(const(char)* name, uint* poff) {
        assert(type == T_DIR);

        for (uint off = 0; off < size; off += Dirent.sizeof) {
            Dirent de;
            if (read(cast(ubyte*) &de, off, Dirent.sizeof) != Dirent.sizeof)
                assert(0);
            if (de.inum == 0)
                continue;
            if (namecmp(name, de.name.ptr) == 0) {
                if (poff)
                    *poff = off;
                uint inum = de.inum;
                return iget(dev, inum);
            }
        }
        return null;
    }

    int link(const(char)* name, uint inum) {
        Inode* ip;
        if ((ip = lookup(name, null)) != null) {
            put();
            return -1;
        }

        Dirent de;
        int off;
        for (off = 0; off < size; off += Dirent.sizeof) {
            if (read(cast(ubyte*) &de, off, Dirent.sizeof) != Dirent.sizeof)
                assert(0);
            if (de.inum == 0)
                break;
        }

        de.inum = cast(ushort) inum;
        if (write(cast(ubyte*) &de, off, Dirent.sizeof) != Dirent.sizeof) {
            return -1;
        }
        return 0;
    }
}

struct Itable {
    Inode[NINODE] inodes;
}

private __gshared Itable itable;

void iinit() {
}

Inode* ialloc(uint dev, short type) {
    for (int inum = 1; inum < sb.ninodes; inum++) {
        Buf* bp = bread(dev, iblock(inum, sb));
        Dinode* dip = cast(Dinode*) bp.data.ptr + inum % IPB;
        if (dip.type == 0) {
            memset(dip, 0, Dinode.sizeof);
            dip.type = type;
            brelease(bp);
            return iget(dev, inum);
        }
        brelease(bp);
    }
    return null;
}

// Find the inode with number inum on device dev and return the in-memory copy.
Inode* iget(uint dev, uint inum) {
    Inode* empty, ip;
    for (usize i = 0; i < itable.inodes.length; i++) {
        ip = &itable.inodes[i];
        if (ip.refcnt > 0 && ip.dev == dev && ip.inum == inum) {
            ip.refcnt++;
            return ip;
        }
        if (!empty && ip.refcnt == 0) {
            empty = ip;
        }
    }

    assert(empty != null, "no inodes");

    ip = empty;
    ip.dev = dev;
    ip.inum = inum;
    ip.refcnt = 1;
    ip.valid = false;
    return ip;
}
