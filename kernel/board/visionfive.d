module kernel.board.visionfive;

import kernel.dev.uart.dw8250;
import kernel.dev.gpio.starfive;
import kernel.dev.reboot.unsupported;

alias Uart = Dw8250!(0x12440000);
alias Gpio = StarfiveGpio!(0x11910000);
alias Reboot = Unsupported;

struct System {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
}
