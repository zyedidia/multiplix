module plix.trap;

import plix.timer : Timer;
import plix.proc : Proc;
import plix.schedule : ticks_queue;
import plix.syscall : sys_exit;
import plix.print : printf;
import plix.vm : lookup, ka2pa, Perm;
import plix.alloc : kalloc;
import plix.page : pages;
import plix.arch.cache : sync_idmem;

import sys = plix.sys;

enum IrqType {
    timer,
}

void irq_handler(IrqType irq) {
    if (irq == IrqType.timer) {
        ticks_queue.wake_all();
        Timer.intr(Timer.time_slice);
    }
}

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

void pgflt_handler(Proc* p, void* addr, FaultType fault) {
    noreturn kill() {
        printf("%d: killed: attempted to access %p (pc=%p)\n", p.pid, addr, cast(void*) p.trapframe.epc);
        sys_exit(p);
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
        auto pg = &pages[map.pa / sys.pagesize];
        bool pg_irqs = pg.lock();
        scope(exit) pg.unlock(pg_irqs);
        if (pg.refcnt == 1) {
            // We are the only one with a reference, so just take over the page.
            map.pte.perm = (map.perm & ~Perm.cow) | Perm.w;
            return;
        }

        // Decrease the old page's reference count.
        pg.refcnt--;
        ubyte[] mem = null;
        while (!mem) {
            // Block while waiting for available memory.
            mem = kalloc(sys.pagesize);
            if (!mem) {
                // XXX: could have a memq for processes blocked waiting for memory
                p.block(&ticks_queue);
                p.yield();
            }
        }
        import builtins : memcpy;
        // Copy the page data.
        memcpy(mem.ptr, cast(void*) map.ka, sys.pagesize);
        // Mark the page as writable and no longer copy-on-write, and point it
        // to the new physical address.
        map.pte.perm = map.perm & ~Perm.cow | Perm.w;
        map.pte.pa = ka2pa(cast(uintptr) mem.ptr);

        // Increase the page's reference count.
        bool irqs = pages[map.pte.pa / sys.pagesize].lock();
        pages[map.pte.pa / sys.pagesize].refcnt++;
        pages[map.pte.pa / sys.pagesize].unlock(irqs);

        if (map.exec()) {
            // Need to sync instruction/data caches for executable pages.
            sync_idmem(cast(ubyte*) mem.ptr, mem.length);
        }

        return;
    }

    kill();
}

noreturn unhandled(Proc* p) {
    printf("%d: killed (unhandled)\n", p.pid);
    sys_exit(p);
}
