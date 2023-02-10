module kernel.fs.api;

import kernel.proc;
import kernel.spinlock;

import ulib.iface;

struct Vnode {
    struct Vtbl {
        size_t function(File* fd, Proc* p, ubyte[] buf) read;
        size_t function(File* fd, Proc* p, ubyte[] buf) write;
        long function(File* fd, long to, int flag) seek_loc;
        bool function() seekable;
        void function(File* fd) onclose;
    }
}

struct File {
    Vnode* vnode;
    long offset;
    uint refcount;
    ulong perm;
    Spinlock lock;

    long seek(long where, int flag) { return -1; }
    this(Vnode* vnode, ulong perm) {}
}

struct Fdtable {
    enum FnoCount = 16;

    File*[FnoCount] files;
    uint refcount;
    Spinlock lock;

    File* reference(int fd) { return null; }
    void deref(File* file);
    void close(int fd);
}

struct Vfs {
    struct Vtbl {
        File function(char* path, ulong perm) open;
        char* function() root_path;
        Vnode function() root;
    }
}
