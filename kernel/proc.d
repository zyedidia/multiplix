module kernel.proc;

import kernel.arch;

struct Proc {
    enum State {
        runnable,
        running,
    }

    Pagetable* pt;
    Regs regs;
    State state;

    void init(byte[] binary, uintptr baseva, uintptr entryva) {
        // allocate physical space for binary, and copy it in
        // allocate pagetable
        // map newly allocated physical space to base va
        // allocate and map stack
        // initialize registers (stack, pc)
        // append to proclist
    }
}
