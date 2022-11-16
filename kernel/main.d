module kernel.main;

import core.volatile;

import dev = kernel.board.virt.dev;
import arch = kernel.arch.riscv;

import vm = kernel.vm;
import sys = kernel.sys;
import kernel.alloc;

import io = ulib.io;

void kmain() {
    io.writeln("kernel booted");
    arch.trap_init();
    arch.trap_enable();
    kallocinit();
    io.writeln(kalloc_page());

    while (true) {}
}

extern (C) {
    void ulib_tx(ubyte b) {
        dev.Uart.tx(b);
    }

    void ulib_exit(ubyte code) {
        dev.SysCon.shutdown();
    }
}
