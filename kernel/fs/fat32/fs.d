module kernel.fs.fat32.fs;

import kernel.board;
import kernel.proc;
import kernel.alloc;

import kernel.fs.vfs;
import kernel.fs.fat32.fat32 : Fat32FS;

struct FatFile {
    Fat32FS* fs;
    uint cluster;
    ubyte[] rdata;
    size_t size;

    ulong offset;

    ssize_t read(File* fd, Proc* p, ubyte[] buf) {
        fd.lock.lock();
        if ((fd.perm & File.Perm.read) == 0) {
            // not readable
            return -1;
        }

        if (!rdata) {
            // load file
            rdata = fs.readfile(cluster, size);
        }

        import ulib.memory;
        import ulib.math;
        memcpy(&buf[0], &rdata[offset], min(buf.length, rdata.length - offset));

        fd.lock.unlock();
        return 0;
    }

    ssize_t write(File* fd, Proc* p, ubyte[] buf){
        return -1;
    }

    off_t seek(File* fd, off_t to, int flag) {
        offset = to;
        return offset;
    }

    bool seekable() {
        return true;
    }

    void close(File* fd) {
        kfree(rdata.ptr);
    }
}
