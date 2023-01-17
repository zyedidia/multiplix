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

    static void setup(uint baud) {
        device_fence();

        Gpio.set_func(Gpio.PinType.tx, Gpio.FuncType.alt5);
        Gpio.set_func(Gpio.PinType.rx, Gpio.FuncType.alt5);

        device_fence();

        volatile_st(aux_enables, volatile_ld(aux_enables) | enable_uart);

        device_fence();

        volatile_st(&uart.cntl, 0);
        volatile_st(&uart.ier, 0);
        volatile_st(&uart.lcr, 0b11);
        volatile_st(&uart.mcr, 0);
        volatile_st(&uart.iir, iir_reset | clear_fifos);
        volatile_st(&uart.baud, System.gpu_freq / (baud * 8) - 1);
        volatile_st(&uart.cntl, rx_enable | tx_enable);

        device_fence();
    }

    static bool rx_empty() {
        return bits.get(volatile_ld(&uart.stat), 0) == 0;
    }

    static uint rx_sz() {
        return bits.get(volatile_ld(&uart.stat), 19, 16);
    }

    static bool can_tx() {
        return bits.get(volatile_ld(&uart.stat), 1) != 0;
    }

    static ubyte rx() {
        device_fence();
        while (rx_empty()) {
        }
        ubyte c = volatile_ld(&uart.io) & 0xff;
        device_fence();
        return c;
    }

    static void tx(ubyte c) {
        device_fence();
        while (!can_tx()) {
        }
        volatile_st(&uart.io, c & 0xff);
        device_fence();
    }

    static bool tx_empty() {
        device_fence();
        return bits.get(volatile_ld(&uart.stat), 9) == 1;
    }

    static void tx_flush() {
        while (!tx_empty()) {
        }
    }
}
