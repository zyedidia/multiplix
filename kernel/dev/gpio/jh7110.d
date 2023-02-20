module kernel.dev.gpio.jh7110;

import core.volatile;

import bits = ulib.bits;
import io = ulib.io;

struct Jh7110Gpio(uintptr base) {
    enum doen = cast(uint*)(base + 0x0);
    enum dout = cast(uint*)(base + 0x40);

    static void set(uint pin) {
        if (pin > 63) {
            return;
        }

        uint offset = pin / 4;
        uint shift = 8 * (pin % 4);

        uint dout_off = volatile_ld(&dout[offset]);
        uint doen_off = volatile_ld(&doen[offset]);

        volatile_st(&dout[offset], bits.write(dout_off, shift+6, shift, 1));
        // enable is active low
        volatile_st(&doen[offset], bits.clear(doen_off, shift+5, shift));
    }

    static void clear(uint pin) {
        if (pin > 63) {
            return;
        }

        uint offset = pin / 4;
        uint shift = 8 * (pin % 4);

        uint dout_off = volatile_ld(&dout[offset]);
        volatile_st(&dout[offset], bits.write(dout_off, shift+6, shift, 0));
    }

    static void write(uint pin, bool value) {
        if (value) {
            set(pin);
        } else {
            clear(pin);
        }
    }
}
