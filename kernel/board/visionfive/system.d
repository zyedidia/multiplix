module kernel.board.visionfive.system;

import kernel.dev.uart.dw8250;
import kernel.dev.reboot.sbi;
import kernel.dev.gpio.starfive;
import kernel.vm;

version (baremetal) {
    alias Uart = Dw8250!(0x12440000);
    alias Reboot = SbiReboot;
    alias Gpio = StarfiveGpio!(cast(uint*) 0x11910000);
} else {
    alias Uart = Dw8250!(pa2ka(0x12440000));
    alias Reboot = SbiReboot;
    alias Gpio = StarfiveGpio!(cast(uint*) pa2ka(0x11910000));
}
