module kernel.syscall;

import core.sync;

import kernel.proc;
import kernel.timer;
import kernel.schedule;
import kernel.vm;
import kernel.board;
import kernel.alloc;
import kernel.arch;

import kernel.fs.vfs;

import sys = kernel.sys;
import vm = kernel.vm;

import io = ulib.io;

import ulib.memory;
import ulib.option;
import ulib.vector;
import ulib.list;

uintptr syscall_handler(Args...)(Proc* p, ulong sysno, Args args) {
    uintptr ret = 0;
    switch (sysno) {
        case Syscall.Num.write:
            Syscall.write(p, cast(int) args[0], args[1], cast(size_t) args[2]);
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
        default:
            io.writeln("invalid syscall: ", sysno);
            return -1;
    }

    return ret;
}

struct Syscall {
    enum Num {
        write  = 0,
        getpid = 1,
        exit   = 2,
        fork   = 3,
        wait   = 4,
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
        waiter.state = Proc.State.waiting;
        runq.wait(waiter.node);
        schedule();
    }
}
