module test.main;

import io = ulib.io;
import kernel.board;

import kernel.arch.aarch64.sysreg;
import kernel.arch.aarch64.monitor.boot;

/* import sbi = kernel.arch.riscv64.sbi; */
/*  */
/* import kernel.arch.riscv64.csr; */
/* import kernel.arch.riscv64.monitor.boot; */

extern (C) void kmain() {
    Uart.init(115200);

    /* enter_smode(); */

    io.writeln("address of kmain: ", &kmain);

    io.writeln("entering el1, from el: ", SysReg.currentel >> 2);

    enter_el1();

    io.writeln("hello world");
    io.writeln("current el: ", SysReg.currentel >> 2);

    asm {
        "smc 0";
    }

    /* io.writeln("mvendorid: ", sbi.Base.get_mvendorid()); */

    /* io.writeln("hart: ", Csr.mhartid, " misa: ", Csr.misa); */
}
