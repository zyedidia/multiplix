module kernel.syscall;

import kernel.proc;
import kernel.timer;
import kernel.schedule;

import io = ulib.io;

import ulib.option;

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
        ptable.sched_lock.lock();
        curproc = Opt!(Proc*).none;
        ptable.sched_lock.unlock();
        p.unlock();

        if (ptable.length == 0) {
            // TODO: we are shutting down the machine automatically when the last process exits
            import kernel.board;
            Reboot.shutdown();
        }
    }
}
