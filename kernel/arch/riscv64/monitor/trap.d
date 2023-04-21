module kernel.arch.riscv64.monitor.trap;

import kernel.arch.riscv64.regs;
import kernel.arch.riscv64.csr;
import kernel.arch.riscv64.monitor.ext;
import kernel.arch.riscv64.monitor.dbg;

import sbi = kernel.arch.riscv64.sbi;

import bits = ulib.bits;

extern (C) void monitortrap(Regs* regs) {
    auto mcause = Csr.mcause;
    auto mepc = Csr.mepc;

    switch (mcause) {
        case Cause.ecall_s, Cause.ecall_m:
            // sbi_handler(regs);
            Csr.mepc = mepc + 4;
            break;
        case Cause.mti:
            Csr.mie = bits.clear(Csr.mie, Mie.mtie);
            Csr.mip = Csr.mip | (1 << Mip.stip);
            break;
        case Cause.breakpoint:
            // auto mtval = Csr.mtval;
            // if (mepc == mtval) {
            ExtDebug.handle_breakpoint(mepc, regs);
            // } else {
            //     ExtDebug.handle_watchpoint(mepc, mtval, regs);
            // }
            break;
        default:
            import core.exception;
            panic("[unhandled cause] monitortrap: core: ", Csr.mhartid, ", cause: ", mcause, ", epc: ", cast(void*) mepc, ", mtval: ", cast(void*) Csr.mtval);
    }
}
