module plix.page;

import plix.spinlock : Spinlock;
import plix.board : Machine;

import sys = plix.sys;

struct Page {
    uint refcnt;
    shared Spinlock lock_;

    bool lock() {
        return lock_.lock();
    }

    void unlock(bool irqs) {
        lock_.unlock(irqs);
    }
}

struct Pages {
    enum basepg = Machine.main_memory.start / sys.pagesize;
    enum npgs = Machine.main_memory.sz / sys.pagesize;

    private Page[npgs] pages;

    ref Page opIndex(usize pn) return {
        return pages[pn - basepg];
    }
}

__gshared Pages pages;
