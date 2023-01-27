module kernel.syscall;

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
        p.lock();
        // TODO: free the process
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

        schedule();
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

        System.allocator.checkpoint();
        // kalloc a pagetable
        auto pt_ = kalloc!(Pagetable)();
        if (!pt_.has()) {
            System.allocator.free_checkpoint();
            return -1;
        }
        child.pt = pt_.get();

        // kalloc+map trapframe
        auto trapframe_ = kalloc_block(sys.pagesize);
        if (!trapframe_.has()) {
            System.allocator.free_checkpoint();
            return -1;
        }
        child.trapframe = cast(Trapframe*) trapframe_.get();
        if (!child.pt.map(Proc.trapframeva, vm.ka2pa(cast(uintptr) child.trapframe), Pte.Pg.normal, Perm.krwx, &System.allocator)) {
            System.allocator.free_checkpoint();
            return false;
        }

        assert(kernel_map(child.pt));

        foreach (vmmap; p.pt.range()) {
            if (!vmmap.user) {
                continue;
            }
            auto block_ = kalloc_block(vmmap.size);
            if (!block_.has()) {
                System.allocator.free_checkpoint();
                return -1;
            }
            memcpy(block_.get(), cast(void*) vmmap.ka(), vmmap.size);
            if (!child.pt.map(vmmap.va, vm.ka2pa(cast(uintptr) block_.get()), Pte.Pg.normal, Perm.urwx, &System.allocator)) {
                System.allocator.free_checkpoint();
                return -1;
            }
        }
        System.allocator.done_checkpoint();

        child.state = Proc.State.runnable;

        memcpy(&child.trapframe.regs, &p.trapframe.regs, Regs.sizeof);
        version (RISCV64) {
            child.trapframe.regs.a0 = 0;
        } else version (Aarch64) {
            child.trapframe.regs.x0 = 0;
        }

        child.trapframe.epc = p.trapframe.epc;
        child.trapframe.p = child;

        return child.pid;
    }
}
