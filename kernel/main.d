module kernel.main;

import io = ulib.io;
import core.volatile;

import dev = kernel.board.virt.dev;
import trap = kernel.arch.riscv.trap;
import timer = kernel.arch.riscv.timer;

void kmain() {
    io.writeln("kernel booted");
    trap.init();
    trap.enable();

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
