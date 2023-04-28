module plix.dev.uart.bcmmini;

import core.volatile : vst, vld;
import bits = core.bits;

import plix.arch.cache : device_fence;
import plix.dev.gpio.bcm : BcmGpio;

// Driver for the Broadcom MiniUART.

struct BcmMiniUart {
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

    uint* aux_enables;
    AuxPeriphs* uart;

    this(uintptr base) {
        aux_enables = cast(uint*)(base + 0x4);
        uart = cast(AuxPeriphs*)(base + 0x40);
    }

    void setup(uint baud, uint gpu_freq, BcmGpio gpio) {
        device_fence();

        gpio.set_func(BcmGpio.PinType.tx, BcmGpio.FuncType.alt5);
        gpio.set_func(BcmGpio.PinType.rx, BcmGpio.FuncType.alt5);

        device_fence();

        vst(aux_enables, vld(aux_enables) | enable_uart);

        device_fence();

        vst(&uart.cntl, 0);
        vst(&uart.ier, 0);
        vst(&uart.lcr, 0b11);
        vst(&uart.mcr, 0);
        vst(&uart.iir, iir_reset | clear_fifos);
        vst(&uart.baud, gpu_freq / (baud * 8) - 1);
        vst(&uart.cntl, rx_enable | tx_enable);

        device_fence();
    }

    bool rx_empty() {
        return bits.get(vld(&uart.stat), 0) == 0;
    }

    uint rx_sz() {
        return bits.get(vld(&uart.stat), 19, 16);
    }

    bool can_tx() {
        return bits.get(vld(&uart.stat), 1) != 0;
    }

    ubyte rx() {
        device_fence();
        while (rx_empty()) {
        }
        ubyte c = vld(&uart.io) & 0xff;
        device_fence();
        return c;
    }

    void tx(ubyte c) {
        device_fence();
        while (!can_tx()) {
        }
        vst(&uart.io, c & 0xff);
        device_fence();
    }

    bool tx_empty() {
        device_fence();
        return bits.get(vld(&uart.stat), 9) == 1;
    }

    void tx_flush() {
        while (!tx_empty()) {
        }
    }
}
