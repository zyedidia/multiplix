module kernel.dev.gpio.bflb;

import core.volatile;
import bits = ulib.bits;

struct BouffaloLabsGpio(uintptr base) {

    struct GpioConfig {
        uint data;
        mixin(bits.field!(data, "input_enable", 1, "schmidtt_trigger_enable", 1,
                "drive_strength", 2, "pullup_enable", 1, "pulldown_enable", 1, "output_enable", 1, "_0",
                1, "func", 5, "_1", 3, "interrupt_mode", 4, "interrupt_clear", 1,
                "interrupt_state", 1, "interrupt_mask", 1, "_2", 1, "output_value", 1,
                "output_set", 1, "output_clear", 1, "_3", 1, "input_value", 1,
                "_4", 1, "io_mode", 2,));
    }

    enum PinType {
        tx = 14,
        rx = 15,
    }

    enum FuncType {
        sdh = 0,
        spi0,
        flash,
        i2s,
        pdm,
        i2c0,
        i2c1,
        uart,
        emac,
        cam,
        analog,
        gpio,
        pwm0,
        pwm1,
        spi1,
        i2c2,
        i2c3,
        mm_uart,
        dbi_b,
        dbi_c,
        dpi,
        jtag_lp,
        jtag_m0,
        jtag_d0,
        clock_out,
    }

    enum IoMode {
        normal = 0,
        set_clear,
        buffer,
        cache,
    }

    enum config = cast(uint*)(base + 0x8c4);
    enum set = cast(uint*)(base + 0xaec);
    enum clr = cast(uint*)(base + 0xaf4);
    enum lev = cast(uint*)(base + 0xac4);

    static void set_func(uint pin, FuncType fn) {
        if (pin >= 46)
            return;

        GpioConfig cfg;
        cfg.input_enable = false, cfg.schmidtt_trigger_enable = true, cfg.drive_strength = 3,
            cfg.pullup_enable = false, cfg.pulldown_enable = false,
            cfg.output_enable = false, cfg.func = cast(ubyte) fn,
            cfg.io_mode = IoMode.normal, vst(config + pin, cfg.data);
    }

    static void set_output(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.input_enable = false;
        cfg.output_enable = true;
        vst(config + pin, cfg.data);
    }

    static void set_input(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.input_enable = true;
        cfg.output_enable = false;
        vst(config + pin, cfg.data);
    }

    static void set_on(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.output_value = true;
        vst(config + pin, cfg.data);
    }

    static void set_off(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.output_value = false;
        vst(config + pin, cfg.data);
    }

    static bool read(uint pin) {
        if (pin >= 46)
            return 0;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        return cast(bool) cfg.input_value;
    }

    static void set_pullup(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.pullup_enable = true;
        cfg.pulldown_enable = false;
        vst(config + pin, cfg.data);
    }

    static void set_pulldown(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.pullup_enable = false;
        cfg.pulldown_enable = true;
        vst(config + pin, cfg.data);
    }

    static void set_floating(uint pin) {
        if (pin >= 46)
            return;
        GpioConfig cfg;
        cfg.data = vld(config + pin);
        cfg.pullup_enable = false;
        cfg.pulldown_enable = false;
        vst(config + pin, cfg.data);
    }
}
