module kernel.arch.riscv64.tls;

import core.sync;

int rd_coreid() {
    int coreid;
    asm {
        "mv %0, tp" : "=r"(coreid);
    }
    return coreid;
}

void wr_coreid(int coreid) {
    asm {
        "mv tp, %0" : : "r"(coreid) : "memory";
    }
}
