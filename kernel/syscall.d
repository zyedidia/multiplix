module kernel.syscall;

import core.sync;

import kernel.proc;
import kernel.timer;
import kernel.schedule;
import kernel.vm;
import kernel.board;
import kernel.alloc;
import kernel.arch;

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
            ret = Syscall.fork(p);
            break;
        case Syscall.n_wait:
            ret = Syscall.wait(p, cast(int) args[0]);
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
    static noreturn exit(Proc* p) {
        io.writeln("process ", p.pid, " exited ");

        foreach (node; p.waiters) {
            auto waiter = node.val;
            version (RISCV64) {
                waiter.trapframe.regs.a0 = p.pid;
            } else version (AArch64) {
                waiter.trapframe.regs.x0 = p.pid;
            }
            io.writeln("waking up ", node.val.pid);
            runq.done_wait(node);
        }

        // remove p from runnable
        runq.exit(p.node);

        schedule();
    }

    enum n_fork = 3;
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

        // kalloc+map trapframe
        void* trapframe = kalloc_custom(&alloc, sys.pagesize);
        if (!trapframe) {
            alloc.free_checkpoint();
            return -1;
        }
        child.trapframe = cast(Trapframe*) trapframe;
        if (!child.pt.map(Proc.trapframeva, vm.ka2pa(cast(uintptr) child.trapframe), Pte.Pg.normal, Perm.krwx, &alloc)) {
            alloc.free_checkpoint();
            return -1;
        }

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
        version (RISCV64) {
            child.trapframe.regs.a0 = 0;
        } else version (AArch64) {
            child.trapframe.regs.x0 = 0;
        }

        child.trapframe.epc = p.trapframe.epc;
        child.update_trapframe();

        child.pid = atomic_rmw_add(&nextpid, 1);

        return child.pid;
    }

    enum n_wait = 4;
    static int wait(Proc* waiter, int pid) {
        io.writeln(waiter.pid, " waiting for ", pid);
        bool do_wait(List!(Proc) queue) {
            foreach (ref p; queue) {
                if (pid == p.val.pid) {
                    if (!p.val.waiters.append(waiter.node)) {
                        return false;
                    }
                    runq.wait(waiter.node);
                    schedule();
                }
            }
            return true;
        }

        foreach (ref p; runq.exited) {
            if (pid == p.val.pid) {
                // child already exited
                // TODO: free p
                io.writeln(pid, " already exited");
                runq.exited.remove(p);
                return pid;
            }
        }

        if (!do_wait(runq.runnable)) goto err;
        if (!do_wait(runq.waiting)) goto err;
err:
        return -1;
    }
}
