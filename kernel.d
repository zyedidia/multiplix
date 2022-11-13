module kernel;

import io = ulib.io;
import core.volatile;

void kmain() {
    io.writeln("Hello world");

    int[4] x = [42, 42, 42, 42];
    int y = 42;
    io.writeln(x[y]);
}

void shutdown() {
    enum poweroff = cast(uint*) 0x100000;
    volatileStore(poweroff, 0x5555);
}
