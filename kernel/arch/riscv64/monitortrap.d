module kernel.arch.riscv64.trap;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;

import sbi = kernel.arch.riscv64.sbi;

import io = ulib.io;

extern (C) void monitortrap(Regs* regs) {
    auto mcause = Csr.mcause;
    auto mepc = Csr.mepc;

    switch (mcause) {
        case Cause.ecall_s, Cause.ecall_m:
            sbi_call(regs);
            Csr.mepc = mepc + 4;
            break;
        default:
            assert(0, "monitortrap: unknown cause");
    }
}

void sbi_call(Regs* regs) {
    switch (regs.a7) {
        case sbi.Base.ext:
            switch (regs.a6) {
                case 4:
                    regs.a0 = 0;
                    regs.a1 = Csr.mvendorid;
                    break;
                case 5:
                    regs.a0 = 0;
                    regs.a1 = Csr.marchid;
                    break;
                default:
                    regs.a0 = 1;
                    break;
            }
            break;
        default:
            regs.a0 = 1;
            break;
    }
}
