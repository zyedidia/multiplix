module kernel.main;

import core.volatile;

import dev = kernel.board.virt.dev;
import arch = kernel.arch.riscv;
import sbi = kernel.arch.riscv.sbi;

import vm = kernel.vm;
import sys = kernel.sys;
import kernel.alloc;

import io = ulib.io;

// The bootloader drops us in here with an identity-mapped pagetable.
void kmain() {
    if (!sbi.Base.probe_extension(sbi.Timer.ext)) {
        io.writeln("timer extension not supported!");
        ulib_exit(1);
    }

    io.writeln("kernel booted");

    arch.timer_irq_init();
    arch.trap_init();
    arch.trap_enable();
    kallocinit();
    io.writeln("allocated page: ", kalloc_page());

    while (true) {
    }
}

extern (C) {
    void ulib_tx(ubyte b) {
        dev.Uart.tx(b);
    }

    void ulib_exit(ubyte code) {
        dev.SysCon.shutdown();
    }
}
