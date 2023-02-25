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
        case Syscall.Num.usleep:
            Syscall.usleep(p, cast(ulong) args[0]);
            break;
        default:
            println("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

struct Syscall {
    import io = ulib.io;
    import kernel.schedule;
    import kernel.vm;
    import kernel.arch;
    import kernel.alloc;
    import ulib.memory;
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

    static int getpid(Proc* p) {
        return p.pid;
    }

    static int fork(Proc* p) {
        // Get a new runnable process.
        Proc* child = runq.next();
        if (!child) {
            return -1;
        }

        // Allocate the pagetable and map the kernel.
        child.pt = knew!(Pagetable)();
        if (!child.pt)
            return -1;
        kernel_procmap(child.pt);

        // Map all user pages from the parent.
        foreach (map; VmRange(p.pt)) {
            if (!map.user) {
                continue;
            }
            void* block = kalloc(map.size);
            if (!block) {
                child.free();
                return -1;
            }
            memcpy(block, cast(void*) map.ka, map.size);
            if (!child.pt.map(map.va, ka2pa(cast(uintptr) block), Pte.Pg.normal, Perm.urwx, &sys.allocator)) {
                kfree(block);
                child.free();
                return -1;
            }
            if (map.exec) {
                // Need to sync instruction/data caches for executable pages.
                sync_idmem(cast(ubyte*) block, map.size);
            }
        }

        // Initialize the child's context based on the parent.
        memcpy(&child.trapframe.regs, &p.trapframe.regs, Regs.sizeof);
        child.trapframe.regs.retval = 0;
        child.trapframe.epc = p.trapframe.epc;
        child.context.sp = child.kstackp();
        child.context.retaddr = cast(uintptr) &Proc.forkret;
        child.parent = p;
        p.children++;
        child.brk = p.brk;

        child.pid = atomic_rmw_add(&nextpid, 1);

        // mark the child as runnable.
        runq.ready(child.node);

        return child.pid;
    }

    static int wait(Proc* waiter) {
        if (waiter.children == 0)
            return -1;

        while (true) {
            foreach (ref zombie; runq.exited) {
                if (zombie.val.parent == waiter) {
                    // child already exited
                    int pid = zombie.val.pid;
                    runq.exited.remove(zombie);
                    zombie.val.free();
                    kfree(zombie);
                    waiter.children--;
                    return pid;
                }
            }
            // block and wait for something to exit
            runq.block(waiter.node);
            waiter.yield();
            // we have woken up, so check the zombies again for a child
        }
    }

    static noreturn exit(Proc* p) {
        println(p.pid, ": exited");
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
        // First time sbrk is called we allocate the first brk page.
        if (p.brk.current == 0) {
            void* pg = kalloc(sys.pagesize);
            if (!pg) {
                return -1;
            }
            if (!p.pt.map(p.brk.initial, ka2pa(cast(uintptr) pg), Pte.Pg.normal, Perm.urwx, &sys.allocator)) {
                kfree(pg);
                return -1;
            }
            p.brk.current = p.brk.initial;
        }

        // Requested increment brings the brk beyond maxva or the initial brk.
        if (p.brk.current + incr >= Proc.maxva || p.brk.current + incr < p.brk.initial) {
            return -1;
        }

        uintptr newbrk = p.brk.current;
        if (incr > 0) {
            newbrk = p.pt.alloc(p.brk.current, p.brk.current + incr, Perm.urwx);
            if (!newbrk)
                return -1;
        } else if (incr < 0) {
            newbrk = p.pt.dealloc(p.brk.current, p.brk.current + incr);
        }
        p.brk.current = newbrk;
        return newbrk;
    }

    static void usleep(Proc* p, ulong us) {
        import kernel.timer;

        ulong start_time = Timer.time();

        while (true) {
            runq.block(p.node);
            p.yield();

            if (Timer.us_since(start_time) >= us) {
                return;
            }
        }
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
            return -1; // E_FAULT
        }

        for (uintptr va = addr - (addr & 0xFFF); va < addr + sz; va += sys.pagesize) {
            auto vmap = p.pt.lookup(va);
            if (!vmap.has() || !vmap.get().user) {
                return -1; // E_FAULT
            }
        }

        // TODO: We only support console stdout for now.
        if (fd != 1) {
            return -1;
        }

        ubyte[] buf = (cast(ubyte*) addr)[0 .. sz];
        import kernel.board;
        foreach (c; buf) {
            Uart.tx(c);
        }

        return sz;
    }

    static int close(Proc* p, int fd) {
        return -1;
    }

    static int exec(char* path, char** argv) {
        return -1;
    }
}

