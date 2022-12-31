module kernel.main;

import io = ulib.io;

import kernel.board;

extern (C) void kmain() {
    Uart.init(115200);

    io.writeln("entered kmain at: ", &kmain);
}
