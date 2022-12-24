module kernel.arch.riscv64.monitor.trap;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.monitor.ext;

import sbi = kernel.arch.riscv64.sbi;

import io = ulib.io;

extern (C) void monitortrap(Regs* regs) {
    auto mcause = Csr.mcause;
    auto mepc = Csr.mepc;

    switch (mcause) {
        case Cause.ecall_s, Cause.ecall_m:
            sbi_handler(regs);
            Csr.mepc = mepc + 4;
            break;
        default:
            assert(0, "monitortrap: unknown cause");
    }
}
