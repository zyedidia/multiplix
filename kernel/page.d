module kernel.page;

struct Page {
    uint refcount;
}

import kernel.board;
import sys = kernel.sys;

Page[Machine.memsize / sys.pagesize] pages;
