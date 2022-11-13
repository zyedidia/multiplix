module kernel;

import io = ulib.io;
import core.bitop;

void kmain() {
    io.writeln("Hello world");
}

void shutdown() {
    enum poweroff = cast(uint*) 0x100000;
    volatileStore(poweroff, 0x5555);
}
