module kernel.arch.aarch64.trap;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.regs;
import kernel.arch.aarch64.timer;

import io = ulib.io;
import bits = ulib.bits;

extern (C) extern void kernelvec();

struct Trap {
    static void setup() {
        SysReg.vbar_el1 = cast(uintptr) &kernelvec;
    }

    // TODO: use daifset and daifclr instead
    // enable/disble fiq and irq
    static void enable() {
        // setting a bit to 0 unmasks (enables) the irq
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b1100);
    }

    static void disable() {
        SysReg.daif = bits.write(SysReg.daif, 9, 6, 0b1111);
    }

    static bool enabled() {
        return ((SysReg.daif >> 6) & 0b11) != 0;
    }
}

extern (C) void kernel_exception(Regs* regs) {
    io.writeln("kernel exception");
}

extern (C) void kernel_interrupt(Regs* regs) {
    import kernel.cpu;
    io.writeln("core: ", cpuinfo.coreid, ", kernel interrupt");
    Timer.intr();
}
