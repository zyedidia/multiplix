module kernel.arch.riscv64.monitor.trap;

import plix.arch.riscv64.regs : Regs;
import plix.arch.riscv64.csr : Csr, Mie, Mip, Cause;
import plix.monitor : fwi_handler;

import bits = core.bits;

extern (C) void monitortrap(Regs* regs) {
    auto mcause = Csr.mcause;
    auto mepc = Csr.mepc;

    switch (mcause) {
    case Cause.ecall_s, Cause.ecall_m:
        Csr.mepc = mepc + 4;
        cast(void) fwi_handler(regs.a7);
        break;
    case Cause.mti:
        Csr.mie = bits.clear(Csr.mie, Mie.mtie);
        Csr.mip = Csr.mip | (1 << Mip.stip);
        break;
    case Cause.breakpoint:
        break;
    default:
        import core.exception : panicf;
        panicf("[unhandled cause] monitortrap: core: %lu, cause: %lx, epc: %lx, mtval: %lx", Csr.mhartid, mcause, mepc, Csr.mtval);
    }
}
