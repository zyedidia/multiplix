module plix.fs.bcache;

enum {
    BSIZE = 1024,
    MAXOPBLOCKS = 10,       // max # of blocks any FS op writes
    NBUF = MAXOPBLOCKS * 3, // size of disk block cache
}

struct Buf {
    bool valid;
    bool disk;
    uint dev;
    uint blocknum;
    uint refcnt;

    ubyte[BSIZE] data;

    Buf* next;
    Buf* prev;
}

struct BufferCache {
    Buf[NBUF] buf;
    Buf head;
    Disk* disk;
}

struct Disk {
    void function(Buf* b) read;
    void function(Buf* b) write;
}

private __gshared BufferCache bcache;

void binit(Disk* disk) {
    bcache.head.prev = &bcache.head;
    bcache.head.next = &bcache.head;
    for (Buf* b = bcache.buf.ptr; b < bcache.buf.ptr + NBUF; b++) {
        b.next = bcache.head.next;
        b.prev = &bcache.head;
        bcache.head.next.prev = b;
        bcache.head.next = b;
    }
    bcache.disk = disk;
}

Buf* bget(uint dev, uint blocknum) {
    for (Buf* b = bcache.head.next; b != &bcache.head; b = b.next) {
        if (b.dev == dev && b.blocknum == blocknum) {
            b.refcnt++;
            return b;
        }
    }

    for (Buf* b = bcache.head.prev; b != &bcache.head; b = b.prev) {
        if (b.refcnt == 0) {
            b.dev = dev;
            b.blocknum = blocknum;
            b.valid = false;
            b.refcnt = 1;
            return b;
        }
    }
    
    assert(0, "bget: no buffers");
}

Buf* bread(uint dev, uint blocknum) {
    Buf* b = bget(dev, blocknum);
    if (!b.valid) {
        bcache.disk.read(b);
        b.valid = true;
    }
    return b;
}

void bwrite(Buf* b) {
    bcache.disk.write(b);
}

void brelease(Buf* b) {
    b.refcnt--;
    if (b.refcnt == 0) {
        b.next.prev = b.prev;
        b.prev.next = b.next;
        b.next = bcache.head.next;
        b.prev = &bcache.head;
        bcache.head.next.prev = b;
        bcache.head.next = b;
    }
}

void bpin(Buf* b) {
    b.refcnt++;
}

void bunpin(Buf* b) {
    b.refcnt--;
}
