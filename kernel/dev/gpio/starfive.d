module kernel.dev.gpio.starfive;

import core.volatile;

struct StarfiveGpio(uintptr base) {
    struct Gpo {
        uint val;
        uint en;
    }

    enum gpo = cast(Gpo*)(base + 0x50);

    static void set(uint pin) {
        if (pin > 63) {
            return;
        }

        volatile_st(&gpo[pin].val, 1);
        // enable is active low
        volatile_st(&gpo[pin].en, 0);
    }

    static void clear(uint pin) {
        if (pin > 63) {
            return;
        }

        volatile_st(&gpo[pin].val, 0);
    }

    static void write(uint pin, uint value) {
        if (value) {
            set(pin);
        } else {
            clear(pin);
        }
    }
}
