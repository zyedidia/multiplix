module kernel.syscall;

import kernel.proc;

import io = ulib.io;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    uintptr ret = 0;
    switch (sysno) {
        case Sysno.putc:
            putc(p, cast(char) args[0]);
            break;
        case Sysno.getpid:
            ret = getpid(p);
            break;
        default:
            io.writeln("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

enum Sysno {
    putc = 0,
    getpid = 1,
}

void putc(Proc* p, char c) {
    io.write(c);
}

int getpid(Proc* p) {
    return p.pid;
}
