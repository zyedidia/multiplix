module kernel.cpu;

struct Cpu {
    int coreid;
    bool primary;
    uintptr stack;

    // for push_off and pop_off
    int noff;
    bool irqen;

    // for timer interrupt wait queue
    import kernel.wait;
    WaitQueue ticksq;
}

import kernel.board;

__gshared Cpu[Machine.ncores] _cpu;
ref Cpu cpu() {
    import kernel.arch : rd_cpu;
    return *rd_cpu();
}
