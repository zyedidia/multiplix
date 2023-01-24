module kernel.syscall;

import kernel.proc;
import kernel.timer;

import io = ulib.io;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    brk();
    uintptr ret = 0;
    switch (sysno) {
        case Syscall.n_putc:
            Syscall.putc(cast(char) args[0]);
            break;
        case Syscall.n_getpid:
            ret = Syscall.getpid(p);
            break;
        case Syscall.n_exit:
            Syscall.exit(p);
            break;
        default:
            io.writeln("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

struct Syscall {
    enum n_putc = 0;
    static void putc(char c) {
        io.write(c);
    }

    enum n_getpid = 1;
    static int getpid(Proc* p) {
        return p.pid;
    }

    enum n_exit = 2;
    static void exit(Proc* p) {
        p.lock();
        p.state = Proc.State.free;
        io.writeln("process ", p.pid, " exited");
        p.unlock();
    }
}
