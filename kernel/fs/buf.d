module kernel.fs.buf;

import kernel.spinlock;

struct Buf {
    enum size = 1024;

    bool valid;
    bool disk;
    uint dev;
    uint blockno;
    shared Spinlock lock;
    uint refcnt;
    Buf* next;
    Buf* prev;
    ubyte[size] data;
}
