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
        cast(void) fwi_handler(regs.a7, regs.a0);
        break;
    case Cause.mti:
        Csr.mie_clear!(Mie.mtie)();
        Csr.mip_set!(Mip.stip)();
        break;
    case Cause.breakpoint:
        break;
    default:
        import core.exception : panicf;
        panicf("[unhandled monitortrap]: core: %lu, cause: %lx, epc: %lx, mtval: %lx\n", Csr.mhartid, mcause, mepc, Csr.mtval);
    }
}

