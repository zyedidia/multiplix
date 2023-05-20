module plix.arch.aarch64.monitor.trap;

import plix.arch.aarch64.regs : Regs;
import plix.arch.aarch64.sysreg : SysReg, Exception;
import plix.cpu : cpu;
import plix.print : println;
import plix.monitor : fwi_handler;

import bits = core.bits;

extern (C) void monitor_exception(Regs* regs) {
    const auto exc_class = bits.get(SysReg.esr_el2, 31, 26);

    switch (exc_class) {
    case Exception.hvc:
        cast(void) fwi_handler(regs.x7, regs.x0);
        break;
    case Exception.brkpt:
        println("TODO: brkpt");
        break;
    case Exception.ss:
        println("TODO: ss");
        break;
    case Exception.wchpt:
        println("TODO: watchpoint");
        break;
    default:
        import core.exception : panicf;
        panicf("[unhandled exception] monitor_exception: core: %u, cause: %lx, elr: %lx\n", cpu.id, exc_class, SysReg.elr_el2);
    }
}

extern (C) void monitor_interrupt(Regs* regs) {
    println("monitor_interrupt, elr_el2: ", cast(void*) SysReg.elr_el2);
}
