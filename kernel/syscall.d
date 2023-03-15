module kernel.syscall;

import kernel.proc;

import ulib.print;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
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
        case Syscall.Num.fork:
            ret = Syscall.fork(p);
            break;
        case Syscall.Num.wait:
            ret = Syscall.wait(p);
            break;
        case Syscall.Num.sbrk:
            ret = Syscall.sbrk(p, cast(int) args[0]);
            break;
        case Syscall.Num.usleep:
            Syscall.usleep(p, cast(ulong) args[0]);
            break;
        default:
            println("invalid syscall: ", sysno);
            return Syscall.Err.E_NOSYS;
    }

    return ret;
}

struct Syscall {
    import kernel.schedule;
    import kernel.vm;
    import kernel.arch;
    import kernel.alloc;
    import libc;
    import core.sync;
    import sys = kernel.sys;

    enum Num {
        write     = 0,
        getpid    = 1,
        exit      = 2,
        fork      = 3,
        wait      = 4,
        sbrk      = 5,
        usleep    = 6,
        read      = 7,
    }

    enum Err {
        E_AGAIN = -11,       // Try again
        E_BADF = -9,         // Bad file number
        E_CHILD = -10,       // No child processes
        E_FAULT = -14,       // Bad address
        E_FBIG = -27,        // File too large
        E_INTR = -4,         // Interrupted system call
        E_INVAL = -22,       // Invalid argument
        E_IO = -5,           // I/O error
        E_MFILE = -24,       // Too many open files
        E_NFILE = -23,       // File table overflow
        E_NOENT = -2,        // No such file or directory
        E_NOEXEC = -8,       // Exec format error
        E_NOMEM = -12,       // Out of memory
        E_NOSPC = -28,       // No space left on device
        E_NOSYS = -38,       // Invalid system call number
        E_NXIO = -6,         // No such device or address
        E_PERM = -1,         // Operation not permitted
        E_PIPE = -32,        // Broken pipe
        E_SPIPE = -29,       // Illegal seek
        E_SRCH = -3,         // No such process
        E_TXTBSY = -26,      // Text file busy
        E_2BIG = -7,         // Argument list too long
    }

    static int getpid(Proc* p) {
        return p.pid;
    }

    static int fork(Proc* p) {
        // Get a new runnable process.
        Proc* child = runq.next();
        if (!child) {
            return Err.E_NOMEM;
        }

        // Allocate the pagetable and map the kernel.
        child.pt = knew!(Pagetable)();
        if (!child.pt)
            return Err.E_NOMEM;
        kernel_procmap(child.pt);

        // Map all user pages from the parent.
        foreach (map; VmRange(p.pt)) {
            if (!map.user) {
                continue;
            }
            // parent and child both get page read-only with copy-on-write
            map.pte.perm = (map.perm & ~Perm.w) | Perm.cow;
            if (!child.pt.mappg(map.va, map.pa, Perm.urx | Perm.cow)) {
                child.free();
                return Err.E_NOMEM;
            }
        }
        assert(p.canary == Proc.canary_magic);

        // Initialize the child's context based on the parent.
        memcpy(&child.trapframe.regs, &p.trapframe.regs, Regs.sizeof);
        child.trapframe.regs.retval = 0;
        child.trapframe.epc = p.trapframe.epc;
        child.context.sp = child.kstackp();
        child.context.retaddr = cast(uintptr) &Proc.forkret;
        child.context.set_pt(child.pt);
        child.parent = p;
        child.canary = Proc.canary_magic;
        p.children++;
        child.brk = p.brk;

        child.pid = atomic_rmw_add(&nextpid, 1);

        // mark the child as runnable.
        child.lock.lock();
        runq.enqueue(child);
        child.lock.unlock();

        return child.pid;
    }

    import kernel.wait;
    // Exited processes, waiting to be reaped by parents.
    static shared WaitQueue exited;
    // Waiting processes, waiting for a child to exit.
    static shared WaitQueue waiters;

    // Wait for a child to exit.
    static int wait(Proc* waiter) {
        if (waiter.children == 0)
            return Err.E_CHILD;

        while (true) {
            exited.lock.lock();
            foreach (ref zombie; (cast()exited).procs) {
                if (zombie.val.parent == waiter) {
                    // Child has exited.
                    int pid = zombie.val.pid;
                    (cast()exited).procs.remove(zombie);
                    zombie.val.free();
                    printf("1: %p %p\n", zombie, waiter);
                    kfree(zombie);
                    waiter.children--;
                    printf("2\n");
                    exited.lock.unlock();
                    return pid;
                }
            }
            exited.lock.unlock();
            // Block and wait for something to exit.
            waiter.lock.lock();
            waiters.enqueue(waiter);
            waiter.block(cast(void*) &waiters);
            // We have woken up, so check the zombies again for a child.
        }
    }

    static noreturn exit(Proc* p) {
        println(p.pid, ": exited");
        import kernel.schedule;

        {
            p.lock.lock();
            p.state = Proc.State.exited;
            exited.enqueue(p);

            if (p.parent) {
                p.parent.lock.lock();

                // Wake up parent if they are waiting in the waiters queue.
                if (p.parent && p.parent.state == Proc.State.blocked && p.parent.wq == &waiters) {
                    waiters.wake_one(p.parent);
                }
                p.parent.lock.unlock();
            }
            p.lock.unlock();
        }
        p.yield();

        import core.exception;
        panic("exited process resumed");
    }

    static uintptr sbrk(Proc* p, int incr) {
        // First time sbrk is called we allocate the first brk page.
        if (p.brk.current == 0) {
            void* pg = kalloc(sys.pagesize);
            if (!pg) {
                return Err.E_NOMEM;
            }
            if (!p.pt.mappg(p.brk.initial, ka2pa(cast(uintptr) pg), Perm.urwx)) {
                kfree(pg);
                return Err.E_NOMEM;
            }
            p.brk.current = p.brk.initial;
        }

        // Requested increment brings the brk beyond maxva or the initial brk.
        if (p.brk.current + incr >= Proc.maxva || p.brk.current + incr < p.brk.initial) {
            return Err.E_INVAL;
        }

        uintptr newbrk = p.brk.current;
        if (incr > 0) {
            newbrk = p.pt.alloc(p.brk.current, p.brk.current + incr, Perm.urwx);
            if (!newbrk)
                return Err.E_NOMEM;
        } else if (incr < 0) {
            newbrk = p.pt.dealloc(p.brk.current, p.brk.current + incr);
        }
        p.brk.current = newbrk;
        return newbrk;
    }

    static void usleep(Proc* p, ulong us) {
        import kernel.timer;

        ulong start_time = Timer.time();

        import kernel.trap;
        import kernel.cpu;
        p.lock.lock();
        while (1) {
            // Add this process to this core's ticks queue. It will be woken up
            // every timer tick, and if the sleep time has been reached, the
            // process will remove itself from the ticks queue and stay
            // runnable.
            cpu.ticksq.enqueue_(p);
            if (Timer.us_since(start_time) >= us) {
                break;
            }
            import kernel.cpu;
            p.block(&cpu.ticksq);
            p.lock.lock();
        }
        cpu.ticksq.remove_(p);
        p.lock.unlock();
    }

    static int open(Proc* p, char* path, int flags) {
        return -1;
    }

    static long read(Proc* p, int fd, uintptr addr, size_t sz) {
        return -1;
    }

    static long write(Proc* p, int fd, uintptr addr, size_t sz) {
        if (sz == 0) {
            return 0;
        }

        // Validate buffer.
        size_t overflow = addr + sz;
        if (overflow < addr || addr >= Proc.maxva) {
            return Err.E_FAULT;
        }

        for (uintptr va = addr - (addr & 0xFFF); va < addr + sz; va += sys.pagesize) {
            auto vmap = p.pt.lookup(va);
            if (!vmap.has() || !vmap.get().user) {
                return Err.E_FAULT;
            }
        }

        // TODO: We only support console stdout for now.
        if (fd != 1) {
            return Err.E_BADF;
        }

        string buf = cast(string) (cast(ubyte*) addr)[0 .. sz];
        print(buf);

        return sz;
    }

    static int close(Proc* p, int fd) {
        return -1;
    }

    static int exec(char* path, char** argv) {
        return -1;
    }
}

