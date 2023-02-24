module kernel.syscall;

import kernel.proc;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    import io = ulib.io;

    uintptr ret = 0;
    switch (sysno) {
        case Syscall.Num.write:
            ret = Syscall.write(p, cast(int) args[0], args[1], cast(size_t) args[2]);
            break;
        case Syscall.Num.read:
            ret = Syscall.read(p, cast(int) args[0], args[1], cast(size_t) args[2]);
            break;
        case Syscall.Num.getpid:
            ret = Syscall.getpid(p);
            break;
        case Syscall.Num.exit:
            Syscall.exit(p);
            break;
        case Syscall.Num.fork:
            ret = Syscall.fork(p);
            break;
        case Syscall.Num.wait:
            ret = Syscall.wait(p);
            break;
        case Syscall.Num.sbrk:
            ret = Syscall.sbrk(p, cast(int) args[0]);
            break;
        default:
            io.writeln("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

struct Syscall {
    import io = ulib.io;

    enum Num {
        write     = 0,
        getpid    = 1,
        exit      = 2,
        fork      = 3,
        wait      = 4,
        sbrk      = 5,
        read      = 7,
    }

    static int getpid(Proc* p) {
        io.writeln("getpid: ", p.pid);
        return p.pid;
    }

    static int fork(Proc* p) {
        assert(0);
    }

    static int wait(Proc* waiter) {
        assert(0);
    }

    static noreturn exit(Proc* p) {
        io.writeln("process ", p.pid, " exited");
        import kernel.schedule;

        if (p.parent && p.parent.state == Proc.State.blocked) {
            p.parent.trapframe.regs.retval = p.pid;
            p.parent.children--;
            runq.unblock(p.parent.node);
        }

        runq.exit(p.node);
        p.yield();

        import core.exception;
        panic("exited process resumed");
    }

    static uintptr sbrk(Proc* p, int incr) {
        assert(0);
    }

    static void usleep(ulong us) {
        assert(0);
    }

    static int open(Proc* p, char* path, int flags) {
        assert(0);
    }

    static long read(Proc* p, int fd, uintptr addr, size_t sz) {
        assert(0);
    }

    static long write(Proc* p, int fd, uintptr addr, size_t sz) {
        assert(0);
    }

    static int close(Proc* p, int fd) {
        assert(0);
    }

    static int exec(char* path, char** argv) {
        assert(0);
    }
}

