module kernel.board.raspi3;

enum DeviceBase = 0x3f000000;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;

alias Uart = BcmMiniUart!(DeviceBase + 0x215000);
alias Gpio = BcmGpio!(DeviceBase + 0x200000);

struct System {
    enum gpu_freq = 250 * 1000 * 1000;
}
