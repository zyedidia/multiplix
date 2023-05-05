module plix.proc;

import plix.arch.vm : Pagetable;
import plix.arch.trap : Trapframe;

struct Proc {
    Trapframe trapframe;

    Pagetable* pt;

    uint canary;
    align(16) ubyte[3008] kstack;
    static assert(kstack.length % 16 == 0);

    // Returns the top of the kernel stack.
    uintptr kstackp() {
        return cast(uintptr) &kstack[$-16];
    }
}
