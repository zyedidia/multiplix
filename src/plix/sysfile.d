module plix.sysfile;

import plix.proc : Proc, ProcState;
import plix.print : printf, print;
import plix.syscall : Err;
import plix.vm : lookup;

import plix.fs.fs;
import plix.fs.file;
import plix.fs.stat;
import plix.fs.dir;

import sys = plix.sys;

enum Mode {
    RDONLY = 0x000,
    WRONLY = 0x001,
    RDWR   = 0x002,
    CREATE = 0x200,
    TRUNC  = 0x400,
}

private int fdalloc(Proc* p, File* f) {
    for (int fd = 0; fd < p.ofile.length; fd++) {
        if (p.ofile[fd] == null) {
            p.ofile[fd] = f;
            return fd;
        }
    }
    return -1;
}

private Inode* create(Inode* cwd, char* path, short type, short major, short minor) {
    char[DIRSIZ] name;

    Inode* dp;
    if ((dp = nameiparent(cwd, path, name.ptr)) == null) {
        return null;
    }
    dp.lock();
    Inode* ip;
    if ((ip = dp.lookup(name.ptr, null)) != null) {
        dp.unlockput();
        ip.lock();
        if (type == T_FILE && (ip.type == T_FILE || ip.type == T_DEVICE)) {
            return ip;
        }
        ip.unlockput();
        return null;
    }

    if ((ip = ialloc(dp.dev, type)) == null) {
        dp.unlockput();
        return null;
    }

    ip.lock();
    ip.major = major;
    ip.minor = minor;
    ip.nlink = 1;
    ip.update();

    // create . and .. entries
    if (type == T_DIR) {
        if (ip.link(".".ptr, ip.inum) < 0 || ip.link("..".ptr, dp.inum) < 0)
            goto fail;
    }

    if (dp.link(name.ptr, ip.inum) < 0)
        goto fail;

    if (type == T_DIR) {
        dp.nlink++;
        dp.update();
    }
    dp.unlockput();
    return ip;

fail:
    ip.nlink = 0;
    ip.update();
    ip.unlockput();
    dp.unlockput();
    return null;
}

private bool checkfd(Proc* p, int fd) {
    return !(fd < 0 || fd >= Proc.nofile || p.ofile[fd] == null);
}

private bool checkaddr(Proc* p, uintptr addr, usize sz) {
    // Validate buffer.
    usize overflow = addr + sz;
    if (overflow < addr || addr >= Proc.max_va) {
        return false;
    }

    for (uintptr va = addr - (addr & 0xFFF); va < addr + sz; va += sys.pagesize) {
        auto vmap = p.pt.lookup(va);
        if (!vmap.has() || !vmap.get().user) {
            return false;
        }
    }
    return true;
}

ulong sys_open(Proc* p, char* path, int mode) {
    Inode* ip;
    if (mode & Mode.CREATE) {
        ip = create(p.cwd, path, T_FILE, 0, 0);
        if (!ip) {
            return -1;
        }
    } else {
        if ((ip = namei(p.cwd, path)) == null) {
            return -1;
        }
        ip.lock();
        if (ip.type == T_DIR && mode != Mode.RDONLY) {
            ip.unlockput();
            return -1;
        }
    }

    // TODO: T_DEVICE

    File* f;
    int fd;
    if ((f = falloc()) == null || (fd = fdalloc(p, f)) < 0) {
        if (f)
            f.close();
        ip.unlockput();
        return -1;
    }

    if (ip.type == T_DEVICE) {
        f.type = Ft.DEVICE;
        f.major = ip.major;
    } else {
        f.type = Ft.INODE;
        f.off = 0;
    }
    f.ip = ip;
    f.readable = !(mode & Mode.WRONLY);
    f.writable = (mode & Mode.WRONLY) || (mode & Mode.RDWR);

    if ((mode & Mode.TRUNC) && ip.type == T_FILE) {
        ip.trunc();
    }

    ip.unlock();
    return fd;
}

long sys_close(Proc* p, int fd) {
    if (!checkfd(p, fd)) {
        return -1;
    }
    File* f = p.ofile[fd];
    p.ofile[fd] = null;
    f.close();
    return 0;
}

long sys_fstat(Proc* p, int fd, Stat* st) {
    if (!checkfd(p, fd)) {
        return -1;
    }
    return p.ofile[fd].stat(cast(uintptr) st);
}

long sys_dup(Proc* p, int fd) {
    if (!checkfd(p, fd)) {
        return -1;
    }
    File* f = p.ofile[fd];
    int nfd = fdalloc(p, f);
    if (nfd < 0)
        return -1;
    return nfd;
}

int sys_read(Proc* p, int fd, uintptr addr, usize sz) {
    if (sz == 0)
        return 0;
    if (!checkfd(p, fd))
        return -1;
    if (!checkaddr(p, addr, sz))
        return Err.fault;

    return p.ofile[fd].read(addr, cast(int) sz);
}

long sys_write(Proc* p, int fd, uintptr addr, usize sz) {
    if (sz == 0)
        return 0;
    if (!checkfd(p, fd))
        return -1;
    if (!checkaddr(p, addr, sz))
        return Err.fault;

    return p.ofile[fd].write(addr, cast(int) sz);
}

long sys_chdir(Proc* p, const(char)* path) {
    // TODO: check that path does not exceed MAXPATH
    Inode* ip;
    if ((ip = namei(p.cwd, path)) == null) {
        return -1;
    }
    ip.lock();
    if (ip.type != T_DIR) {
        ip.unlockput();
        return -1;
    }
    ip.unlock();
    p.cwd.put();
    p.cwd = ip;
    return 0;
}
