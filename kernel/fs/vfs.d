module kernel.fs.vfs;

import kernel.proc;
import kernel.spinlock;
import kernel.alloc;

import ulib.iface;

alias Path = string;

struct Vnode {
    uint refcount;
    shared Spinlock lock;
    VnodeIf vnode;

    this(uint rc, VnodeIf vn) {
        refcount = rc;
        vnode = vn;
    }

    alias vnode this;
}

struct VnodeIf {
    struct Vtbl {
        ssize_t function(File* fd, Proc* p, ubyte[] buf) read;
        ssize_t function(File* fd, Proc* p, ubyte[] buf) write;
        off_t function(File* fd, off_t to, int flag) seek;
        bool function() seekable;
        void function(File* fd) close;
    }

    mixin MakeInterface!(VnodeIf);
}

struct File {
    enum Perm {
        read  = 0b100000000,
        write = 0b010000000,
        exec  = 0b001000000,
    }

    Vnode* vnode;
    uint refcount;
    ulong perm;
    shared Spinlock lock;

    this(Vnode* vnode, ulong perm) {
        this.vnode = vnode;
        this.perm = perm;
    }

    off_t seek(off_t where, int flag) {
        if (vnode.seekable()) {
            return -1;
        }
        return vnode.seek(&this, where, flag);
    }
}

struct FdTable {
    enum fno_count = 16;

    File*[fno_count] files;
    shared Spinlock lock;
    uint refcount;

    File* reference(int fd) {
        lock.lock();
        File* f = files[fd];
        f.lock.lock();
        lock.unlock();
        f.refcount++;
        f.lock.unlock();

        return f;
    }

    void deref(File* f) {
        f.lock.lock();
        scope(exit) f.lock.unlock();

        f.refcount--;
    }

    void close(int fd) {
        lock.lock();

        File* closef = files[fd];
        closef.lock.lock();
        closef.refcount--;

        if (closef.refcount <= 0) {
            Vnode* node = closef.vnode;
            node.close(closef);
            node.lock.lock();
            node.refcount--;
            if (node.refcount <= 0) {
                kfree(node.self);
            } else {
                node.lock.unlock();
            }
            kfree(closef);
        } else {
            closef.lock.unlock();
        }
        files[fd] = null;
        lock.unlock();
    }
}

struct Vfs {
    struct Vtbl {
        File function(Path path, ulong perm) open;
        Path function() root_path;
        Vnode function() root;
    }

    mixin MakeInterface!(Vfs);
}
