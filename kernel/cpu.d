module kernel.cpu;

struct Cpu {
    int coreid;
    bool primary;
    uintptr stack;

    // For push_off and pop_off.
    int noff;
    bool irqen;

    // For timer interrupt wait queue.
    import kernel.wait;
    WaitQueue ticksq;

    version (sanitizer) {
        bool asan_active;
    }
}

import kernel.board;

__gshared Cpu[Machine.ncores] _cpu;

// Returns a reference to this core's cpu struct.
ref Cpu cpu() {
    import kernel.arch : rd_cpu;
    return *rd_cpu();
}
