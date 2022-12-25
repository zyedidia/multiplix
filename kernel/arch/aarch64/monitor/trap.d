module kernel.arch.aarch64.monitor.trap;

import kernel.arch.aarch64.regs;

import io = ulib.io;

extern (C) void monitor_exception(Regs* regs) {
    ulong elr;
    asm {
        "mrs %0, elr_el3" : "=r"(elr);
    }

    io.writeln("exception, elr_el3: ", cast(void*) elr);
}

extern (C) void monitor_interrupt(Regs* regs) {
}
