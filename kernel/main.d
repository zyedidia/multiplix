module kernel.main;

import io = ulib.io;

extern (C) void kmain() {
    io.writeln("entered kmain at: ", &kmain);
}
