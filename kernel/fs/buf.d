module kernel.fs.buf;

import kernel.sleeplock;

struct Buf {
    enum size = 1024;

    bool valid;
    bool disk;
    uint dev;
    uint blockno;
    shared Sleeplock lock;
    uint refcnt;
    Buf* next;
    Buf* prev;
    ubyte[size] data;
}
