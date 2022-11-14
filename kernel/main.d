module kernel.main;

import io = ulib.io;
import core.volatile;

import dev = kernel.board.virt.dev;
import arch = kernel.arch.riscv;

void kmain() {
    io.writeln("kernel booted");
    arch.trap_init();
    arch.trap_enable();

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
