module kernel.arch.aarch64.monitor.trap;

import core.volatile;
import core.sync;

import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.sysreg;

import io = ulib.io;
import bits = ulib.bits;

extern (C) extern __gshared uint wakeup;

extern (C) void monitor_exception(Regs* regs) {
    auto exc_class = bits.get(SysReg.esr_el3, 31, 26);

    switch (exc_class) {
        case Exception.smc:
            volatile_st(&wakeup, 1);
            device_fence();
            asm { "sev"; }
            break;
        default:
            assert(0, "monitor_exception: unknown exception class");
    }
}

extern (C) void monitor_interrupt(Regs* regs) {
    io.writeln("monitor interrupt, elr_el3: ", cast(void*) SysReg.elr_el3);
}
