module test.main;

import io = ulib.io;
import kernel.board;

import kernel.arch.aarch64.sysreg;

/* import sbi = kernel.arch.riscv64.sbi; */
/*  */
/* import kernel.arch.riscv64.csr; */
/* import kernel.arch.riscv64.monitor.boot; */

extern (C) void kmain() {
    Uart.init(115200);
    /* int el; */
    /* asm { */
    /*     "mrs %0, CurrentEL" : "=r"(el); */
    /* } */
    /* io.writeln("EL: ", el >> 2); */

    /* enter_smode(); */

    io.writeln("hello world");
    io.writeln("current el: ", SysReg.currentel);

    asm {
        "smc 0";
    }

    /* io.writeln("mvendorid: ", sbi.Base.get_mvendorid()); */

    /* io.writeln("hart: ", Csr.mhartid, " misa: ", Csr.misa); */
}
