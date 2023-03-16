module kernel.dev.uart.bflb;

import core.volatile;
import core.sync;

import kernel.board;
import bits = ulib.bits;

// Driver for the Bouffalo Labs UART.

struct BouffaloLabsUart(uintptr base) {
    struct UartRegs {
        uint utx_config;
        uint urx_config;
        uint uart_bit_prd;
        uint data_config;
        uint utx_ir_position;
        uint urx_ir_position;
        uint urx_rto_timer;
        uint uart_sw_mode;
        uint uart_int_sts;
        uint uart_int_mask;
        uint uart_int_clear;
        uint uart_int_en;
        uint uart_status;
        uint sts_urx_abr_prd;
        uint urx_abr_prd_b01;
        uint urx_abr_prd_b23;
        uint urx_abr_prd_b45;
        uint urx_abr_prd_b67;
        uint urx_abr_pw_tol;
        uint urx_bcr_int_cfg;
        uint unknown;
        uint utx_rs485_cfg;
        uint[10] reserved;
        uint uart_fifo_config_0;
        uint uart_fifo_config_1;
        uint uart_fifo_wdata;
        uint uart_fifo_rdata;
    }

    struct TxConfig {
        uint data;
        mixin(bits.field!(data, "enable", 1, "flow_control_en", 1,
                "freerun_en", 1, "lin_en", 1, "parity_en", 1, "parity_odd", 1, "ir_en", 1, "ir_invert", 1,
                "bit_count_minus_one", 3, "stop_bit_count_times_two", 2,
                "break_bit_count", 3, "transfer_length", 16,));
    }

    struct RxConfig {
        uint data;
        mixin(bits.field!(data, "enable", 1, "flow_control_en", 1, "reserved",
                1, "lin_en", 1, "parity_en", 1, "parity_odd", 1, "ir_en", 1, "ir_invert", 1,
                "bit_count_minus_one", 3, "deglitch_en", 1,
                "deglitch_cycle_count", 4, "transfer_length", 16,));
    }

    enum signal_enable = 1;

    enum uart = cast(UartRegs*)(base);

    static void setup(uint baud) {
        device_fence();

        Gpio.set_func(Gpio.PinType.tx, Gpio.FuncType.uart);
        Gpio.set_output(Gpio.PinType.tx);
        Gpio.set_func(Gpio.PinType.rx, Gpio.FuncType.uart);
        Gpio.set_input(Gpio.PinType.rx);
        Gpio.set_pullup(Gpio.PinType.rx);

        device_fence();

        // Turn everything off for config
        vst(&uart.utx_config, 0);
        vst(&uart.urx_config, 0);

        // Set baud rate
        ushort bit_prd = cast(ushort)(Machine.uart_freq / (baud - 1));
        vst(&uart.uart_bit_prd, cast(uint) bit_prd << 16 | bit_prd);

        // Clear the FIFOs
        vst(&uart.uart_fifo_config_0, 0b11 << 2);
        static assert(&uart.uart_fifo_config_0 - &uart.utx_config == 0x80 / 4);

        // Enable as 8n1
        TxConfig tx;
        tx.enable = true;
        tx.freerun_en = true;
        tx.bit_count_minus_one = 7;
        tx.stop_bit_count_times_two = 2;
        RxConfig rx;
        rx.enable = true;
        rx.bit_count_minus_one = 7;

        vst(&uart.utx_config, tx.data);
        vst(&uart.urx_config, rx.data);

        device_fence();
    }

    static bool rx_empty() {
        return rx_sz() == 0;
    }

    static uint rx_sz() {
        device_fence();
        uint x = vld(&uart.uart_fifo_config_1);
        uint n = bits.get(x, 13, 8);
        return n;
    }

    static bool can_tx() {
        device_fence();
        return bits.get(vld(&uart.uart_fifo_config_1), 5, 0) != 0;
    }

    static ubyte rx() {
        while (rx_empty()) {
        }
        ubyte c = vld(&uart.uart_fifo_rdata) & 0xff;
        device_fence();
        return c;
    }

    static void tx(ubyte c) {
        device_fence();
        while (!can_tx()) {
        }
        static assert(&uart.uart_fifo_wdata - &uart.utx_config == 0x88 / 4);
        vst(&uart.uart_fifo_wdata, c & 0xff);
        device_fence();
    }

    static bool tx_empty() {
        device_fence();
        return bits.get(vld(&uart.uart_fifo_config_1), 5, 0) == 32;
    }

    static void tx_flush() {
        while (!tx_empty()) {
        }
    }
}

struct BouffaloLabsUartMux(uintptr base) {
    struct Config {
        uint config;
        uint[2] signal;
    }

    enum Function {
        rts = 0,
        cts,
        tx,
        rx,
    }

    enum Uart {
        uart0 = 0,
        uart1,
        uart2,
    }

    __gshared Config* config = cast(Config*)(base + 0x150);

    static void set_signal_func(uint signal, Uart uart, Function fn) {
        uint reg = signal / 8;
        uint offset = (signal % 8) * 4;
        uint uart_fn = uart * 4 + fn;

        uint v = vld(&config.signal[reg]);
        v = bits.write(v, offset + 3, offset, uart_fn);
        vst(&config.signal[reg], v);
    }

    static void set_pin_func(uint pin, Uart uart, Function fn) {
        set_signal_func(pin % 12, uart, fn);
    }
}
