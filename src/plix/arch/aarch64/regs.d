module plix.arch.aarch64.regs;

struct Regs {
    ulong x0;
    ulong x1;
    ulong x2;
    ulong x3;
    ulong x4;
    ulong x5;
    ulong x6;
    ulong x7;
    ulong x8;
    ulong x9;
    ulong x10;
    ulong x11;
    ulong x12;
    ulong x13;
    ulong x14;
    ulong x15;
    ulong x16;
    ulong x17;
    ulong x18;
    ulong x19;
    ulong x20;
    ulong x21;
    ulong x22;
    ulong x23;
    ulong x24;
    ulong x25;
    ulong x26;
    ulong x27;
    ulong x28;
    ulong fp;
    ulong lr;
    ulong sp; // loaded from sp_el0

    void retval(ulong val) {
        x0 = val;
    }
}

// Kernel thread context
struct Context {
    ulong lr;
    ulong sp;

    // callee-saved
    ulong x19;
    ulong x20;
    ulong x21;
    ulong x22;
    ulong x23;
    ulong x24;
    ulong x25;
    ulong x26;
    ulong x27;
    ulong x28;

    void retaddr(uintptr addr) {
        lr = addr;
    }
}
