module kernel.arch.aarch64.monitor.trap;

import core.volatile;
import core.sync;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.monitor.ext;
import kernel.arch.aarch64.monitor.dbg;

import kernel.cpu;

import bits = ulib.bits;
import ulib.print;

extern (C) void monitor_exception(Regs* regs) {
    const auto exc_class = bits.get(SysReg.esr_el2, 31, 26);

    switch (exc_class) {
        case Exception.hvc:
            fwi_handler(regs);
            break;
        case Exception.brkpt:
            ExtDebug.handle_breakpoint(SysReg.elr_el2, regs);
            break;
        case Exception.ss:
            ExtDebug.handle_ss(SysReg.elr_el2, regs);
            break;
        case Exception.wchpt:
            ExtDebug.handle_watchpoint(SysReg.elr_el2, SysReg.far_el2, regs);
            break;
        default:
            import core.exception;
            panic("[unhandled exception] monitor_exception: core: ", cpu.coreid, ", cause: ", exc_class, " elr: ", cast(void*) SysReg.elr_el2);
    }
}

extern (C) void monitor_interrupt(Regs* regs) {
    println("monitor_interrupt, elr_el2: ", cast(void*) SysReg.elr_el2);
}
