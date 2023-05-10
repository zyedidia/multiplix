module plix.arch.riscv64.regs;

import plix.arch.riscv64.vm : Pagetable;

struct Regs {
    ulong ra;
    ulong sp;
    ulong gp;
    ulong tp;
    ulong t0;
    ulong t1;
    ulong t2;
    ulong s0;
    ulong s1;
    ulong a0;
    ulong a1;
    ulong a2;
    ulong a3;
    ulong a4;
    ulong a5;
    ulong a6;
    ulong a7;
    ulong s2;
    ulong s3;
    ulong s4;
    ulong s5;
    ulong s6;
    ulong s7;
    ulong s8;
    ulong s9;
    ulong s10;
    ulong s11;
    ulong t3;
    ulong t4;
    ulong t5;
    ulong t6;

    void retval(ulong val) {
        a0 = val;
    }
}

struct Context {
    ulong ra;
    ulong sp;

    // callee-saved
    ulong s0;
    ulong s1;
    ulong s2;
    ulong s3;
    ulong s4;
    ulong s5;
    ulong s6;
    ulong s7;
    ulong s8;
    ulong s9;
    ulong s10;
    ulong s11;

    ulong satp;

    this(ulong sp, ulong ra, Pagetable* pt) {
        this.sp = sp;
        this.ra = ra;
        this.satp = pt.satp(0);
    }
}

ulong rdgp() {
    ulong gp;
    asm {
        "mv %0, gp" : "=r"(gp);
    }
    return gp;
}

ulong rdtp() {
    ulong tp;
    asm {
        "mv %0, tp" : "=r"(tp);
    }
    return tp;
}
