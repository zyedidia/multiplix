module kernel.dev.uart.ns16550;

import core.volatile;

// Driver for ns16550 UART.
struct Ns16550(uint* base) {
    static void init() {
    }

    // Currently this device is only used via Qemu, so we don't have to
    // initialize it.
    static void tx(ubyte b) {
        volatileStore(base, b);
    }

    static bool hasRxData() {
        assert(false, "hasRxData is not implemented");
    }

    static ubyte rx() {
        assert(false, "rx is not implemented");
    }

    static void flushTx() {
    }
}
