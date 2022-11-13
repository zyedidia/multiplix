module dev.ns16550;

import core.volatile;

struct Ns16550(uint* base) {
    static void init(uint clock, uint baud) {
        // Not necessary since this device is only used from qemu. Would need
        // to configure the clock for actual hardware
    }

    static void tx(ubyte b) {
        volatileStore(base, b);
    }
}
