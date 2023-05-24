module plix.arch.riscv64.monitor.dbg;

import plix.arch.riscv64.csr : Csr;

enum Brkpt : ulong {
    load = 1 << 0,
    store = 1 << 1,
    exec = 1 << 2,
    user = 1 << 3,
    super_ = 1 << 4,
    eq = 0x0 << 7,
    ge = 0x2 << 7,
    lt = 0x3 << 7,
    chain = 1 << 11,
    match6 = 6UL << 60,
}

void breakpoint(uint n, uintptr addr, Brkpt flags) {
    Csr.tselect = n;
    Csr.tdata1 = flags | Brkpt.match6;
    Csr.tdata2 = addr;
}

void clear(uint n) {
    Csr.tselect = n;
    Csr.tdata1 = Brkpt.match6;
}
