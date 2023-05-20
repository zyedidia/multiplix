module plix.syscall;

import plix.proc : Proc;
import plix.print : printf, print;
import plix.schedule : exit_queue, ticks_queue;

enum Sys {
    WRITE  = 0,
    GETPID = 1,
    EXIT   = 2,
    FORK   = 3,
    WAIT   = 4,
    SBRK   = 5,
    USLEEP = 6,
    READ   = 7,
}

enum Err {
    AGAIN  = -11, // Try again
    BADF   = -9,  // Bad file number
    CHILD  = -10, // No child processes
    FAULT  = -14, // Bad address
    FBIG   = -27, // File too large
    INTR   = -4,  // Interrupted system call
    INVAL  = -22, // Invalid argument
    IO     = -5,  // I/O error
    MFILE  = -24, // Too many open files
    NFILE  = -23, // File table overflow
    NOENT  = -2,  // No such file or directory
    NOEXEC = -8,  // Exec format error
    NOMEM  = -12, // Out of memory
    NOSPC  = -28, // No space left on device
    NOSYS  = -38, // Invalid system call number
    NXIO   = -6,  // No such device or address
    PERM   = -1,  // Operation not permitted
    PIPE   = -32, // Broken pipe
    SPIPE  = -29, // Illegal seek
    SRCH   = -3,  // No such process
    TXTBSY = -26, // Text file busy
    TOOBIG = -7,  // Argument list too long
}

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    uintptr ret;
    switch (sysno) {
    case Sys.WRITE:
        ret = write(p, cast(int) args[0], args[1], args[2]);
        break;
    case Sys.READ:
        ret = read(p, cast(int) args[0], args[1], args[2]);
        break;
    case Sys.GETPID:
        ret = getpid(p);
        break;
    case Sys.EXIT:
        exit(p);
    case Sys.FORK:
        ret = fork(p);
        break;
    case Sys.WAIT:
        ret = wait(p);
        break;
    case Sys.SBRK:
        ret = sbrk(p, cast(int) args[0]);
        break;
    case Sys.USLEEP:
        usleep(p, cast(ulong) args[0]);
        break;
    default:
        printf("invalid syscall: %lu\n", sysno);
        return Err.NOSYS;
    }
    return ret;
}

int getpid(Proc* p) {
    return p.pid;
}

int fork(Proc* p) {
    assert(false, "unimplemented");
}

int wait(Proc* p) {
    assert(false, "unimplemented");
}

noreturn exit(Proc* p) {
    printf("%d: exited\n", p.pid);
    p.exit(&exit_queue);
    p.yield();
    assert(0, "exited process resumed");
}

uintptr sbrk(Proc* p, int incr) {
    return -1;
}

void usleep(Proc* p, ulong us) {
    import plix.timer : Timer;

    ulong start = Timer.time();

    while (true) {
        if (Timer.us_since(start) >= us) {
            break;
        }
        p.block(&ticks_queue);
        p.yield();
    }
}

int read(Proc* p, int fd, uintptr addr, usize sz) {
    assert(false, "unimplemented");
}

long write(Proc* p, int fd, uintptr addr, usize sz) {
    if (sz == 0) {
        return 0;
    }

    // Validate buffer.
    usize overflow = addr + sz;
    if (overflow < addr || addr >= Proc.MAX_VA) {
        return Err.FAULT;
    }

    // TODO: validate
    // for (uintptr va = addr - (addr & 0xFFF); va < addr + sz; va += sys.pagesize) {
    //     auto vmap = p.pt.lookup(va);
    //     if (!vmap.has() || !vmap.get().user) {
    //         return Err.E_FAULT;
    //     }
    // }

    // TODO: We only support console stdout for now.
    if (fd != 1) {
        return Err.BADF;
    }

    string buf = cast(string) (cast(ubyte*) addr)[0 .. sz];
    print(buf);

    return sz;
}
