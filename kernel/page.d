module kernel.page;

import kernel.spinlock;

// Tracks information about every page in the system. Currently, this tracks a
// reference count for each page, for copy-on-write. A page may only be freed
// when it reaches a reference count of 0.
struct Page {
    uint refcount;
    shared Spinlock _lock;

    alias _lock this;
}

import kernel.board;
import sys = kernel.sys;

shared Page[Machine.memsize / sys.pagesize] pages;
