module plix.syscall;

import plix.proc : Proc, ProcState;
import plix.print : printf, print;
import plix.schedule : exit_queue, ticks_queue, wait_queue, runq;
import plix.alloc: kfree;
import plix.vm : lookup;

import sys = plix.sys;

enum Sys {
    write  = 0,
    getpid = 1,
    exit   = 2,
    fork   = 3,
    wait   = 4,
    sbrk   = 5,
    usleep = 6,
    read   = 7,
}

enum Err {
    again  = -11, // Try again
    badf   = -9,  // Bad file number
    child  = -10, // No child processes
    fault  = -14, // Bad address
    fbig   = -27, // File too large
    intr   = -4,  // Interrupted system call
    inval  = -22, // Invalid argument
    io     = -5,  // I/O error
    mfile  = -24, // Too many open files
    nfile  = -23, // File table overflow
    noent  = -2,  // No such file or directory
    noexec = -8,  // Exec format error
    nomem  = -12, // Out of memory
    nospc  = -28, // No space left on device
    nosys  = -38, // Invalid system call number
    nxio   = -6,  // No such device or address
    perm   = -1,  // Operation not permitted
    pipe   = -32, // Broken pipe
    SPIPE  = -29, // Illegal seek
    srch   = -3,  // No such process
    txtbsy = -26, // Text file busy
    toobig = -7,  // Argument list too long
}

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    uintptr ret;
    switch (sysno) {
    case Sys.write:
        ret = sys_write(p, cast(int) args[0], args[1], args[2]);
        break;
    case Sys.read:
        ret = sys_read(p, cast(int) args[0], args[1], args[2]);
        break;
    case Sys.getpid:
        ret = sys_getpid(p);
        break;
    case Sys.exit:
        sys_exit(p);
    case Sys.fork:
        ret = sys_fork(p);
        break;
    case Sys.wait:
        ret = sys_wait(p);
        break;
    case Sys.sbrk:
        ret = sys_sbrk(p, cast(int) args[0]);
        break;
    case Sys.usleep:
        sys_usleep(p, cast(ulong) args[0]);
        break;
    default:
        printf("invalid syscall: %lu\n", sysno);
        return Err.nosys;
    }
    return ret;
}

int sys_getpid(Proc* p) {
    return p.pid;
}

int sys_fork(Proc* p) {
    Proc* child = Proc.make_from_parent(p);
    if (!child) {
        return Err.nomem;
    }
    child.trapframe.regs.retval = 0;
    p.children++;

    int pid = child.pid;
    runq.push_front(child);
    return pid;
}

int sys_wait(Proc* p) {
    if (p.children == 0)
        return Err.child;

    while (true) {
        foreach (ref zombie; exit_queue) {
            if (zombie.parent == p) {
                int pid = zombie.pid;
                exit_queue.remove(zombie);
                kfree(zombie);
                p.children--;
                return pid;
            }
        }

        p.block(&wait_queue);
        p.yield();
    }
}

noreturn sys_exit(Proc* p) {
    printf("%d: exited\n", p.pid);

    if (p.parent && p.parent.state == ProcState.blocked && p.parent.wq == cast(void*) &wait_queue) {
        wait_queue.wake(p.parent);
    }

    p.exit(&exit_queue);
    p.yield();
    assert(0, "exited process resumed");
}

uintptr sys_sbrk(Proc* p, int incr) {
    return -1;
}

void sys_usleep(Proc* p, ulong us) {
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

int sys_read(Proc* p, int fd, uintptr addr, usize sz) {
    assert(false, "unimplemented");
}

long sys_write(Proc* p, int fd, uintptr addr, usize sz) {
    if (sz == 0) {
        return 0;
    }

    // Validate buffer.
    usize overflow = addr + sz;
    if (overflow < addr || addr >= Proc.max_va) {
        return Err.fault;
    }

    for (uintptr va = addr - (addr & 0xFFF); va < addr + sz; va += sys.pagesize) {
        auto vmap = p.pt.lookup(va);
        if (!vmap.has() || !vmap.get().user) {
            return Err.fault;
        }
    }

    // TODO: We only support console stdout for now.
    if (fd != 1) {
        return Err.badf;
    }

    string buf = cast(string) (cast(ubyte*) addr)[0 .. sz];
    print(buf);

    return sz;
}
