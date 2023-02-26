module kernel.trap;

import kernel.proc;

enum IrqType {
    timer,
}

// Irq handler for kernel interrupts.
void irq_handler(IrqType irq) {
    if (irq == IrqType.timer) {
        import kernel.schedule;
        foreach (ref p; runq.blocked) {
            runq.unblock(p);
        }
        import kernel.timer;
        Timer.intr();
    }
}

// Irq handler for user interrupts.
void irq_handler(Proc* p, IrqType irq) {
    irq_handler(irq);

    if (irq == IrqType.timer) {
        p.yield();
    }
}

enum FaultType {
    read,
    write,
    exec,
}

import kernel.vm;
import sys = kernel.sys;

void pgflt_handler(Proc* p, void* addr, FaultType fault) {
    noreturn kill() {
        import kernel.syscall;
        println(p.pid, ": killed: attempted to access ", addr, " (pc=", cast(void*) p.trapframe.epc, ")");
        Syscall.exit(p);
    }

    uintptr pgaddr = cast(uintptr) addr - (cast(uintptr) addr & 0xFFF);
    auto map_ = p.pt.lookup(pgaddr);
    if (!map_.has() || !map_.get().user() || map_.get().size != sys.pagesize) {
        kill();
    }
    auto map = map_.get();

    if (fault == FaultType.write && map.cow() && map.read()) {
        import kernel.page;
        Page* pg = &pages[map.pa / sys.pagesize];
        if (pg.refcount == 1) {
            // we are the only one with a reference, so just take over the page
            map.pte.perm = map.perm & ~Perm.cow | Perm.w;
            return;
        }

        // copy-on-write
        pages[map.pa / sys.pagesize].refcount--;
        void* mem = null;
        while (!mem) {
            import kernel.schedule;
            import kernel.alloc;
            // block while waiting for available memory
            mem = kalloc(sys.pagesize);
            if (!mem) {
                runq.block(p.node);
                p.yield();
            }
        }
        import ulib.memory;
        memcpy(mem, cast(void*) map.ka, sys.pagesize);
        import kernel.arch;
        map.pte.perm = map.perm & ~Perm.cow | Perm.w;
        map.pte.pa = ka2pa(cast(uintptr) mem);

        if (map.exec()) {
            import core.sync;
            // Need to sync instruction/data caches for executable pages.
            sync_idmem(cast(ubyte*) mem, map.size);
        }

        return;
    }

    kill();
}

noreturn unhandled(Proc* p) {
    import kernel.syscall;
    println(p.pid, ": killed (unhandled)");
    Syscall.exit(p);
}
