module kernel.arch.aarch64.monitor.trap;

import core.volatile;
import core.sync;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.monitor.ext;
import kernel.arch.aarch64.monitor.dbg;

import kernel.cpu;

import io = ulib.io;
import bits = ulib.bits;

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
        default:
            io.writeln("monitor_exception: core: ", cpuinfo.coreid, ", cause: ", exc_class, " elr: ", cast(void*) SysReg.elr_el2);
            assert(0, "monitor_exception: unhandled exception class");
    }
}

extern (C) void monitor_interrupt(Regs* regs) {
    io.writeln("monitor_interrupt, elr_el2: ", cast(void*) SysReg.elr_el2);
}
