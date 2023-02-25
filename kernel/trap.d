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

    if (fault == FaultType.write && !map.write() && map.read()) {
        // copy-on-write
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
        // must succeed because it doesn't allocate
        assert(p.pt.map(map.va, ka2pa(cast(uintptr) mem), Pte.Pg.normal, map.perm | Perm.w, &sys.allocator));

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
    Syscall.exit(p);
}
