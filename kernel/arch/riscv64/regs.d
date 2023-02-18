module kernel.arch.riscv64.regs;

struct Regs {
    uintptr ra;
    uintptr sp;
    uintptr gp;
    uintptr tp;
    uintptr t0;
    uintptr t1;
    uintptr t2;
    uintptr s0;
    uintptr s1;
    uintptr a0;
    uintptr a1;
    uintptr a2;
    uintptr a3;
    uintptr a4;
    uintptr a5;
    uintptr a6;
    uintptr a7;
    uintptr s2;
    uintptr s3;
    uintptr s4;
    uintptr s5;
    uintptr s6;
    uintptr s7;
    uintptr s8;
    uintptr s9;
    uintptr s10;
    uintptr s11;
    uintptr t3;
    uintptr t4;
    uintptr t5;
    uintptr t6;

    void wr_ret(uintptr val) {
        a0 = val;
    }
}

uintptr rd_gp() {
    uintptr gp;
    asm {
        "mv %0, gp" : "=r"(gp);
    }
    return gp;
}

uintptr rd_tp() {
    uintptr tp;
    asm {
        "mv %0, tp" : "=r"(tp);
    }
    return tp;
}
