module kernel.syscall;

import kernel.proc;
import kernel.timer;
import kernel.schedule;
import kernel.vm;

import io = ulib.io;

import ulib.option;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
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
        case Syscall.n_fork:
            Syscall.fork(p);
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

    enum n_fork = 3;
    static int fork(Proc* p) {
        auto child_ = ptable.next();
        if (!child_.has()) {
            return -1;
        }
        auto child = child_.get();
        child.lock();
        scope(exit) child.unlock();

        // kalloc a pagetable

        // kalloc+map trapframe

        foreach (map; p.pt.range()) {
            // pa = kalloc(map.size)
            // map(child.pt, map.va, pa)
        }

        child.state = Proc.State.runnable;

        return child.pid;
    }
}
