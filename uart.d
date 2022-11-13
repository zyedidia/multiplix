module uart;

import core.volatile;

enum addr = cast(ubyte*) 0x10000000;

void tx(ubyte b) {
    volatileStore(addr, b);
}
