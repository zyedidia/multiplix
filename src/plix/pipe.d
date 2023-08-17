module plix.pipe;

import plix.fs.file;
import plix.alloc;

enum PIPESIZE = 512;

struct Pipe {
    char[PIPESIZE] data;
    uint nread;     // number of bytes read
    uint nwrite;    // number of bytes written
    bool readopen;  // read fd is still open
    bool writeopen; // write fd is still open

    static bool alloc(File** f0, File** f1) {
        Pipe* pi;

        if ((*f0 = falloc()) == null || (*f1 = falloc()) == null)
            goto bad;
        if ((pi = knew!(Pipe)()) == null)
            goto bad;
        pi.readopen = true;
        pi.writeopen = true;
        pi.nwrite = 0;
        pi.nread = 0;
        (*f0).type = Ft.PIPE;
        (*f0).readable = true;
        (*f0).writable = false;
        (*f0).pipe = pi;
        (*f1).type = Ft.PIPE;
        (*f1).readable = false;
        (*f1).writable = true;
        (*f1).pipe = pi;
        return true;

bad:
        if (pi)
            kfree(pi);
        if (*f0)
            (*f0).close();
        if (*f1)
            (*f1).close();
        return false;
    }

    void close(bool writable) {
        if (writable) {
            writeopen = false;
            // TODO: wakeup
        } else {
            readopen = false;
            // TODO: wakeup
        }
        if (!readopen && !writeopen) {
            kfree(&this);
        }
    }

    int write(uintptr addr, int n) {
        return 0;
    }

    int read(uintptr addr, int n) {
        return 0;
    }
}
