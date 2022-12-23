module kernel.dev.uart.ns16550;

import core.volatile;

// Driver for ns16550 UART.
struct Ns16550(uintptr base) {
    static void init(int baud) {
    }

    // Currently this device is only used via Qemu, so we don't have to
    // initialize it.
    static void tx(ubyte b) {
        volatileStore(cast(uint*) base, b);
    }

    static bool rx_empty() {
        return true;
    }

    static ubyte rx() {
        return 0;
    }

    static void tx_flush() {
    }
}
