module kernel.trap;

import kernel.proc;

enum IrqType {
    timer,
}

import kernel.cpu;

import ulib.print;

// Irq handler for kernel interrupts.
void irq_handler(IrqType irq) {
    if (irq == IrqType.timer) {
        // Wake all processes on the ticksq.
        cpu.ticksq.wake_all_();
        import kernel.timer;
        // Schedule a new timer interrupt.
        Timer.intr();
    }
}

// Irq handler for user interrupts.
void irq_handler(Proc* p, IrqType irq) {
    // Run the kernel interrupt handler and then yield this process.
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

// Called when a user process experiences a page fault.
void pgflt_handler(Proc* p, void* addr, FaultType fault) {
    noreturn kill() {
        import kernel.syscall;
        printf("%d: killed: attempted to access %p (pc=%p)\n", p.pid, addr, cast(void*) p.trapframe.epc);
        Syscall.exit(p);
    }

    // Check if this page is accessible.
    uintptr pgaddr = cast(uintptr) addr - (cast(uintptr) addr & 0xFFF);
    auto map_ = p.pt.lookup(pgaddr);
    if (!map_.has() || !map_.get().user() || map_.get().size != sys.pagesize) {
        // Not accessible -- kill the process.
        kill();
    }

    auto map = map_.get();
    // If this page is supposed to be copy-on-write, we should perform the copy now.
    if (fault == FaultType.write && map.cow() && map.read()) {
        import kernel.page;
        auto pg = &pages[map.pa / sys.pagesize];
        pg.lock();
        scope(exit) pg.unlock();
        if (pg.refcount == 1) {
            // We are the only one with a reference, so just take over the page.
            map.pte.perm = (map.perm & ~Perm.cow) | Perm.w;
            return;
        }

        // Decrease the old page's reference count.
        (cast(Page*)pg).refcount--;
        void* mem = null;
        p.lock.lock();
        while (!mem) {
            import kernel.schedule;
            import kernel.alloc;
            // Block while waiting for available memory.
            mem = kalloc(sys.pagesize);
            if (!mem) {
                // XXX: could have a memq for processes blocked waiting for memory
                cpu.ticksq.enqueue_(p);
                p.block(&cpu.ticksq);
                p.lock.lock();
            }
        }
        p.lock.unlock();
        import libc;
        // Copy the page data.
        memcpy(mem, cast(void*) map.ka, sys.pagesize);
        import kernel.arch;
        // Mark the page as writable and no longer copy-on-write, and point it
        // to the new physical address.
        map.pte.perm = map.perm & ~Perm.cow | Perm.w;
        map.pte.pa = ka2pa(cast(uintptr) mem);

        // Increase the page's reference count.
        pages[map.pte.pa / sys.pagesize].lock();
        (cast(Page) pages[map.pte.pa / sys.pagesize]).refcount++;
        pages[map.pte.pa / sys.pagesize].unlock();

        if (map.exec()) {
            import core.sync;
            // Need to sync instruction/data caches for executable pages.
            sync_idmem(cast(ubyte*) mem, map.size);
        }

        return;
    }

    // If not amenable to copy-on-write, kill the process.
    kill();
}

noreturn unhandled(Proc* p) {
    import kernel.syscall;
    println(p.pid, ": killed (unhandled)");
    Syscall.exit(p);
}
