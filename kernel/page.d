module kernel.page;

import kernel.spinlock;

struct Page {
    uint refcount;
    shared Spinlock _lock;

    alias _lock this;
}

import kernel.board;
import sys = kernel.sys;

shared Page[Machine.memsize / sys.pagesize] pages;
