module kernel.fs.console;

import kernel.spinlock;
import kernel.board;
import kernel.proc;
import kernel.alloc;

import kernel.fs.vfs;

struct Console {
    ssize_t read(File* fd, Proc* p, ubyte[] buf) {
        fd.vnode.lock.lock();
        fd.lock.lock();

        if ((fd.perm & File.Perm.read) == 0) {
            // not readable
            return -1;
        }

        for (size_t i = 0; i < buf.length; i++) {
            buf[i] = Uart.rx();
        }

        fd.lock.unlock();
        fd.vnode.lock.unlock();

        return buf.length;
    }

    ssize_t write(File* fd, Proc* p, ubyte[] buf) {
        fd.vnode.lock.lock();
        fd.lock.lock();

        if ((fd.perm & File.Perm.write) == 0) {
            // not writable
            return -1;
        }

        foreach (b; buf) {
            Uart.tx(b);
        }
        fd.lock.unlock();
        fd.vnode.lock.unlock();
        return buf.length;
    }

    off_t seek(File* fd, off_t to, int flag) {
        return -1;
    }

    bool seekable() {
        return false;
    }

    void close(File* fd) {}

    __gshared File* stdout;
    __gshared File* stdin;
    __gshared File* stderr;

    static void setup() {
        import io = ulib.io;
        Console* console = knew!(Console)();
        assert(console);
        Vnode* node = knew!(Vnode)(0, VnodeIf.from(console));

        stdin = knew!(File)(node, File.Perm.read);
        stdout = knew!(File)(node, File.Perm.write);
        stderr = knew!(File)(node, File.Perm.write);

        assert(stdin && stdout && stderr);

        node.refcount += 3;
    }
}
