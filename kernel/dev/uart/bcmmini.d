module kernel.dev.uart.bcmmini;

import core.volatile;
import core.sync;

import kernel.board;
import bits = ulib.bits;

// Driver for the Broadcom MiniUART.

struct BcmMiniUart(uintptr base) {
    struct AuxPeriphs {
        uint io;
        uint ier;
        uint iir;
        uint lcr;
        uint mcr;
        uint lsr;
        uint msr;
        uint scratch;
        uint cntl;
        uint stat;
        uint baud;
    }

    enum enable_uart = 1;
    enum rx_enable = 1 << 0;
    enum tx_enable = 1 << 1;
    enum clear_tx_fifo = 1 << 1;
    enum clear_rx_fifo = 1 << 2;
    enum clear_fifos = clear_tx_fifo | clear_rx_fifo;
    enum iir_reset = (0b011 << 6) | 1;

    enum aux_enables = cast(uint*)(base + 0x4);
    enum uart = cast(AuxPeriphs*)(base + 0x40);

    static void init(uint baud) {
        memory_fence();

        Gpio.set_func(Gpio.PinType.tx, Gpio.FuncType.alt5);
        Gpio.set_func(Gpio.PinType.rx, Gpio.FuncType.alt5);

        memory_fence();

        volatileStore(aux_enables, volatileLoad(aux_enables) | enable_uart);

        memory_fence();

        volatileStore(&uart.cntl, 0);
        volatileStore(&uart.ier, 0);
        volatileStore(&uart.lcr, 0b11);
        volatileStore(&uart.mcr, 0);
        volatileStore(&uart.iir, iir_reset | clear_fifos);
        volatileStore(&uart.baud, System.gpu_freq / (baud * 8) - 1);
        volatileStore(&uart.cntl, rx_enable | tx_enable);

        memory_fence();
    }

    static bool rx_empty() {
        return bits.get(volatileLoad(&uart.stat), 0) == 0;
    }

    static uint rx_sz() {
        return bits.get(volatileLoad(&uart.stat), 19, 16);
    }

    static bool can_tx() {
        return bits.get(volatileLoad(&uart.stat), 1) != 0;
    }

    static ubyte rx() {
        memory_fence();
        while (rx_empty()) {
        }
        ubyte c = volatileLoad(&uart.io) & 0xff;
        memory_fence();
        return c;
    }

    static void tx(ubyte c) {
        memory_fence();
        while (!can_tx()) {
        }
        volatileStore(&uart.io, c & 0xff);
        memory_fence();
    }

    static bool tx_empty() {
        memory_fence();
        return bits.get(volatileLoad(&uart.stat), 9) == 1;
    }

    static void tx_flush() {
        while (!tx_empty()) {
        }
    }
}
