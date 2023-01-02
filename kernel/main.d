module kernel.main;

import io = ulib.io;

import kernel.board;

extern (C) void kmain() {
    Uart.init(115200);
    version (AArch64) {
        import kernel.arch.aarch64.sysreg;
        io.writeln("entered kmain at: ", &kmain, " core: ", SysReg.mpidr_el1 & 0xff);
    } else {
        io.writeln("entered kmain at: ", &kmain);
    }
}
