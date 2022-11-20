module kernel.dev.gpio.starfive;

import core.volatile;

struct StarfiveGpio(uint* base) {
    struct Gpo {
        uint val;
        uint en;
    }

    enum gpo = cast(Gpo*) (cast(uintptr) base + 0x50);

    static void set(uint pin) {
        if (pin > 63) {
            return;
        }

        volatileStore(&gpo[pin].val, 1);
        volatileStore(&gpo[pin].en, 0);
    }

    static void clear(uint pin) {
        if (pin > 63) {
            return;
        }

        volatileStore(&gpo[pin].val, 0);
    }

    static void write(uint pin, uint value) {
        if (value) {
            set(pin);
        } else {
            clear(pin);
        }
    }
}
