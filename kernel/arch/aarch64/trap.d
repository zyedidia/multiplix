module kernel.arch.aarch64.trap;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.regs;

import io = ulib.io;
import bits = ulib.bits;

extern (C) extern void kernelvec();

struct Trap {
    static void init() {
        SysReg.vbar_el1 = cast(uintptr) &kernelvec;
    }

    // TODO: use daifset and daifclr instead
    // enable/disble fiq and irq
    static void enable() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0011);
    }

    static void disable() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b0000);
    }

    static bool enabled() {
        return ((SysReg.daif >> 6) & 0b11) != 0;
    }
}

extern (C) void kernel_exception(Regs* regs) {
    io.writeln("kernel exception");
}

extern (C) void kernel_interrupt(Regs* regs) {
    io.writeln("kernel interrupt");
}
