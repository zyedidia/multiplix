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
        case Syscall.n_delay_us:
            Syscall.delay_us(args[0]);
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

    enum n_delay_us = 2;
    static void delay_us(ulong us) {
        Timer.delay_us(us);
    }
}
