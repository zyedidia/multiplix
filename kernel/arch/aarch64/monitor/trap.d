module kernel.arch.aarch64.monitor.trap;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;

import io = ulib.io;

extern (C) void monitor_exception(Regs* regs) {
    io.writeln("exception, elr_el3: ", cast(void*) SysReg.elr_el3);
}

extern (C) void monitor_interrupt(Regs* regs) {
    io.writeln("interrupt, elr_el3: ", cast(void*) SysReg.elr_el3);
}
