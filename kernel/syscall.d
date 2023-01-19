module kernel.syscall;

import kernel.proc;

import io = ulib.io;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    uintptr ret = 0;
    switch (sysno) {
        case Syscall.n_putc:
            Syscall.putc(p, cast(char) args[0]);
            break;
        case Syscall.n_getpid:
            ret = Syscall.getpid(p);
            break;
        default:
            io.writeln("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

struct Syscall {
    enum n_putc = 0;
    static void putc(Proc* p, char c) {
        io.write(c);
    }

    enum n_getpid = 1;
    static int getpid(Proc* p) {
        return p.pid;
    }
}
