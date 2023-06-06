module plix.coremark;

import plix.timer : Timer;
import plix.board : uart;

// functions used by coremark

extern (C) {
    void uart_send_char(ubyte c) {
        uart.tx(c);
    }

    ulong barebones_clock() {
        return Timer.time();
    }
}
