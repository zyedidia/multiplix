module kernel.syscall;

import core.sync;

import kernel.proc;
import kernel.schedule;
import kernel.vm;
import kernel.board;
import kernel.alloc;
import kernel.arch;

import kernel.fs.vfs;

import sys = kernel.sys;
import vm = kernel.vm;

import kernel.vm : unmap;

import io = ulib.io;

import ulib.memory;
import ulib.option;
import ulib.vector;
import ulib.list;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    uintptr ret = 0;
    switch (sysno) {
        case Syscall.Num.write:
            ret = Syscall.write(p, cast(int) args[0], args[1], cast(size_t) args[2]);
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
        case Syscall.Num.nanosleep:
            ret = Syscall.nanosleep(p, args[0]);
            break;
        default:
            io.writeln("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

struct Syscall {
    enum Num {
        write     = 0,
        getpid    = 1,
        exit      = 2,
        fork      = 3,
        wait      = 4,
        sbrk      = 5,
        nanosleep = 6,
    }

    static int write(Proc* p, int fd, uintptr addr, size_t sz) {
        // Validate buffer.
        if (sz != 0) {
            size_t overflow = addr + sz;
            if (overflow < addr || addr >= Proc.stackva) {
                return -1; // E_FAULT
            }

            for (uintptr va = addr - (addr & 0xFFF); va < addr + sz; va += sys.pagesize) {
                auto vmap = vm.lookup(p.pt, va);
                if (!vmap.has() || !vmap.get().user) {
                    return -1; // E_FAULT
                }
            }
        }

        // Validate file descriptor.
        if (fd >= FdTable.FnoCount || fd < 0 || !p.fdtable.files[fd]) {
            return -1; // E_BADF
        }
        File* f = p.fdtable.reference(fd);
        int n = cast(int) f.vnode.write(f, p, (cast(ubyte*) addr)[0 .. sz]);
        p.fdtable.deref(f);
        return n;
    }

    static int getpid(Proc* p) {
        return p.pid;
    }

    static noreturn exit(Proc* p) {
        io.writeln("process ", p.pid, " exited ");

        if (p.parent && p.parent.state == Proc.State.waiting) {
            p.parent.trapframe.regs.wr_ret(p.pid);
            p.parent.children--;
            runq.done_wait(p.parent.node);
        }

        // move p from runnable to exited
        runq.exit(p.node);

        schedule();
    }

    static int fork(Proc* p) {
        auto child_ = runq.queue().next();
        if (!child_.has()) {
            return -1;
        }
        auto child = child_.get();

        auto alloc = CheckpointAllocator!(typeof(sys.allocator))(&sys.allocator);

        alloc.checkpoint();
        // allocate a pagetable
        Pagetable* pt = knew_custom!(Pagetable)(&alloc);
        if (!pt) {
            alloc.free_checkpoint();
            return -1;
        }
        child.pt = pt;

        assert(kernel_map(child.pt));

        foreach (vmmap; p.pt.range()) {
            if (!vmmap.user) {
                continue;
            }
            void* block = kalloc_custom(&alloc, vmmap.size);
            if (!block) {
                alloc.free_checkpoint();
                return -1;
            }
            memcpy(block, cast(void*) vmmap.ka(), vmmap.size);
            if (!child.pt.map(vmmap.va, vm.ka2pa(cast(uintptr) block), Pte.Pg.normal, Perm.urwx, &alloc)) {
                alloc.free_checkpoint();
                return -1;
            }
            // TODO: only sync ID cache for executable pages
            sync_idmem(cast(ubyte*) block, vmmap.size);
        }
        alloc.done_checkpoint();

        memcpy(&child.trapframe.regs, &p.trapframe.regs, Regs.sizeof);
        child.trapframe.regs.wr_ret(0);
        child.trapframe.epc = p.trapframe.epc;
        child.parent = p;
        p.children++;
        child.brk = p.brk;

        child.pid = atomic_rmw_add(&nextpid, 1);

        return child.pid;
    }

    static int wait(Proc* waiter) {
        if (waiter.children == 0) {
            return -1;
        }

        foreach (ref p; runq.exited) {
            if (p.val.parent == waiter) {
                // child already exited
                // TODO: free p
                int pid = p.val.pid;
                runq.exited.remove(p);
                waiter.children--;
                return pid;
            }
        }
        runq.wait(waiter.node);
        schedule();
    }

    static uintptr sbrk(Proc* p, int incr) {
        // First time sbrk is called we allocate the first brk page.
        if (p.brk.current == 0) {
            void* pg = kalloc(sys.pagesize);
            if (!pg) {
                return -1;
            }
            if (!p.pt.map(p.brk.initial, vm.ka2pa(cast(uintptr) pg), Pte.Pg.normal, Perm.urwx, &sys.allocator)) {
                kfree(pg);
                return -1;
            }
            p.brk.current = p.brk.initial;
        }

        if (p.brk.current + incr >= Proc.stackva || p.brk.current + incr < p.brk.initial) {
            return -1;
        }

        uintptr newbrk = p.brk.current;
        if (incr > 0) {
            newbrk = uvmalloc(p.pt, p.brk.current, p.brk.current + incr, Perm.urwx);
            if (!newbrk)
                return -1;
        } else if (incr < 0) {
            newbrk = uvmdealloc(p.pt, p.brk.current, p.brk.current + incr);
        }
        p.brk.current = newbrk;
        return newbrk;
    }

    static int nanosleep(Proc* p, ulong ns) {
        ulong now = Timer.ns();
        // TODO: will wraparound after ~584.9 years
        ulong end = now + ns;

        runq.sleep(p.node, end);

        schedule();
        return 0;
    }
}
