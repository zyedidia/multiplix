module kernel.board.raspi3;

enum DeviceBase = 0x3f000000;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;

alias Uart = BcmMiniUart!(DeviceBase + 0x215000);
alias Gpio = BcmGpio!(DeviceBase + 0x200000);
alias Reboot = BcmReboot!(DeviceBase + 0x10001c, DeviceBase + 0x100024);

struct System {
    enum gpu_freq = 250 * 1000 * 1000;
}
