module plix.dev.gpio.bcm;

import core.volatile : vst, vld;

struct BcmGpio {
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

    uint* fsel;
    uint* set;
    uint* clr;
    uint* lev;

    this(uintptr base) {
        fsel = cast(uint*)(base);
        set = cast(uint*)(base + 0x1C);
        clr = cast(uint*)(base + 0x28);
        lev = cast(uint*)(base + 0x34);
    }

    void set_func(uint pin, FuncType fn) {
        uint off = (pin % 10) * 3;
        uint idx = pin / 10;

        uint v = vld(&fsel[idx]);
        v &= ~(0b111 << off);
        v |= fn << off;
        vst(&fsel[idx], v);
    }

    void set_output(uint pin) {
        set_func(pin, FuncType.output);
    }

    void set_input(uint pin) {
        set_func(pin, FuncType.input);
    }

    void set_on(uint pin) {
        vst(set, 1 << pin);
    }

    void set_off(uint pin) {
        vst(clr, 1 << pin);
    }

    bool read(uint pin) {
        return (vld(lev) >> pin) & 1;
    }
}

