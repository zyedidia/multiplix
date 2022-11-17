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
    /* io.writeln("allocated page: ", kalloc_page()); */

    import sbi = kernel.arch.riscv.sbi;
    bool has_reset = sbi.Base.probe_extension(sbi.Timer.ext);
    io.writeln("has sbi reset extension: ", has_reset);
    uint x = sbi.Base.get_spec_version();
    io.writeln(x);

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
