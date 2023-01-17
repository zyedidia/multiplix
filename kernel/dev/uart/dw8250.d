module kernel.dev.uart.dw8250;

import core.volatile;
import bits = ulib.bits;

// Driver for the Synopsys DesignWare 8250 (aka Synopsys
// DesignWare ABP UART). See the Synopsys DW_apb_uart
// Databook for documentation.

struct Dw8250(uintptr base) {
    // Read registers
    // Receive buffer register
    @property static uint rbr() {
        enum off = base + 0x0;
        return volatile_ld(cast(uint*) off);
    }
    // Divisor latch low
    @property static uint dll() {
        enum off = base + 0x0;
        return volatile_ld(cast(uint*) off);
    }
    // Divisor latch high
    @property static uint dlh() {
        enum off = base + 0x4;
        return volatile_ld(cast(uint*) off);
    }
    // Line control register
    @property static uint lcr() {
        enum off = base + 0xc;
        return volatile_ld(cast(uint*) off);
    }
    // Line status register
    @property static uint lsr() {
        enum off = base + 0x14;
        return volatile_ld(cast(uint*) off);
    }
    // UART status register
    @property static uint usr() {
        enum off = base + 0x14;
        return volatile_ld(cast(uint*) off);
    }

    // Write registers
    // Transmit holding register
    @property static void thr(uint b) {
        enum off = base + 0x0;
        volatile_st(cast(uint*) off, b);
    }
    // Divisor latch low
    @property static void dll(uint b) {
        enum off = base + 0x0;
        volatile_st(cast(uint*) off, b);
    }
    // Divisor latch high
    @property static void dlh(uint b) {
        enum off = base + 0x4;
        volatile_st(cast(uint*) off, b);
    }
    // Line control register
    @property static void lcr(uint b) {
        enum off = base + 0xc;
        volatile_st(cast(uint*) off, b);
    }
    // Fifo control register
    @property static void fcr(uint b) {
        enum off = base + 0x8;
        volatile_st(cast(uint*) off, b);
    }

    enum Lcr {
        dlab = 7, // divisor latch access bit
    }

    enum Lsr {
        dr = 0, // data ready (receiver has data)
        temt = 6, // transmitter empty
        thre = 5, // transmit holding register empty
    }

    enum Fcr {
        fifoen = 0,
    }

    enum Usr {
        busy = 0,
        tfnf = 1, // transmit fifo not full
    }

    static void setup(int baud) {
        // Currently not sure how to set up the UART's baud rate properly, but
        // luckily it seems to be already set up for us by the firmware.

        /* // dll/dlh cannot be accessed until the uart is not busy */
        /* while (bits.get(usr, Usr.busy)) { */
        /* } */
        /*  */
        /* lcr = bits.set(lcr, Lcr.dlab); */
        /* dll = 54; */
        /* dlh = 0; */
        /* lcr = bits.clear(lcr, Lcr.dlab); */
        /*  */
        /* // enable fifos */
        /* fcr = bits.set(0, Fcr.fifoen); */
    }

    static void tx(ubyte b) {
        // wait for thr to be empty
        while (!bits.get(lsr, Lsr.thre)) {
        }
        thr = b;
    }

    static bool rx_empty() {
        return !bits.get(lsr, Lsr.dr);
    }

    static ubyte rx() {
        // wait until we have data available
        while (rx_empty()) {
        }
        return cast(ubyte) rbr;
    }

    static void tx_flush() {
        // wait until the transmitter is empty
        while (!bits.get(lsr, Lsr.thre)) {
        }
    }
}
