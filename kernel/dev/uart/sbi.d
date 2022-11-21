module kernel.dev.uart.sbi;

import sbi = kernel.arch.riscv64.sbi;

import ulib.option;

// An SBI-based UART device. Must be targeting RISC-V. Note that because
// receiving a byte requires calling out to the firmware, this UART is
// extremely slow at receiving and may lose bytes if they are transmitted to
// fast. It is best to only use this device to transmit. Also note that the SBI
// console functions used by this device are expected to be deprecated in the
// future with no replacement.
struct SbiUart {
    __gshared Option!ubyte tmp;

    static void init() {}

    static void tx(ubyte b) {
        sbi.Legacy.putchar(b);
    }

    static bool hasRxData() {
        // since SBI does not provide a way to check if data is available, we
        // have to read a char and if it succeeded cache it in tmp
        if (tmp.has()) {
            return true;
        }
        uint b = sbi.Legacy.getchar();
        if (b > ubyte.max) {
            return false;
        }
        tmp = Option!ubyte(cast(ubyte) b);
        return true;
    }

    static ubyte rx() {
        // wait until data is avaiable
        while (!hasRxData()) {
        }
        ubyte b = tmp.get();
        // reset tmp
        tmp = Option!ubyte.init;
        return b;
    }

    static void flushTx() {}
}
