module test.main;

import io = ulib.io;
import kernel.board;

import sbi = kernel.arch.riscv64.sbi;

extern (C) void kmain() {
    Uart.init(115200);
    /* int el; */
    /* asm { */
    /*     "mrs %0, CurrentEL" : "=r"(el); */
    /* } */
    /* io.writeln("EL: ", el >> 2); */

    io.writeln("hello world");

    io.writeln("mvendorid: ", sbi.Base.get_mvendorid());

    /* io.writeln("hart: ", Csr.mhartid, " misa: ", Csr.misa); */
}
