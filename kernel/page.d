module kernel.page;

import kernel.spinlock;

// Tracks information about every page in the system's main memory. Currently,
// this tracks a reference count for each page, for copy-on-write. A page may
// only be freed when it reaches a reference count of 0.
struct Page {
    uint refcount;
    shared Spinlock _lock;

    alias _lock this;
}

import kernel.board;
import sys = kernel.sys;

struct Pages {
    private Page[Machine.main_memory.sz / sys.pagesize] pages;

    ref shared(Page) opIndex(ulong pn) return shared {
        return pages[pn - Machine.main_memory.start / sys.pagesize];
    }
}

shared Pages pages;
