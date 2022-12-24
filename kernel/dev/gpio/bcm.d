module kernel.dev.gpio.bcm;

import core.volatile;

struct BcmGpio(uintptr base) {
    enum PinType {
        tx = 14,
        rx = 15,
        sda = 2,
        scl = 3,
    }

    enum FuncType {
        input = 0,
        output = 1,
        alt0 = 4,
        alt1 = 5,
        alt2 = 6,
        alt3 = 7,
        alt4 = 3,
        alt5 = 2,
    }

    enum fsel = cast(uint*)(base);
    enum set = cast(uint*)(base + 0x1C);
    enum clr = cast(uint*)(base + 0x28);
    enum lev = cast(uint*)(base + 0x34);

    static void set_func(uint pin, FuncType fn) {
        if (pin >= 32)
            return;
        uint off = (pin % 10) * 3;
        uint idx = pin / 10;

        uint v = volatile_ld(&fsel[idx]);
        v &= ~(0b111 << off);
        v |= fn << off;
        volatile_st(&fsel[idx], v);
    }

    static void set_output(uint pin) {
        set_func(pin, FuncType.output);
    }

    static void set_input(uint pin) {
        set_func(pin, FuncType.input);
    }

    static void set_on(uint pin) {
        if (pin >= 32)
            return;
        volatile_st(set, 1 << pin);
    }

    static void set_off(uint pin) {
        if (pin >= 32)
            return;
        volatile_st(clr, 1 << pin);
    }

    static bool read(uint pin) {
        if (pin >= 32)
            return false;
        return (volatile_ld(lev) >> pin) & 1;
    }

}
