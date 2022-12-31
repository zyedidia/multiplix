module kernel.board.raspi3;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;

struct System {
    enum gpu_freq = 250 * 1000 * 1000;

    enum device_base = 0x3f000000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    private enum mb(ulong n) = 1024 * 1024 * n;
    enum MemRange mem = MemRange(0, mb!(512));
    enum MemRange device = MemRange(device_base, mb!(1024));
}

alias Uart = BcmMiniUart!(System.device_base + 0x215000);
alias Gpio = BcmGpio!(System.device_base + 0x200000);
alias Reboot = BcmReboot!(System.device_base + 0x10001c, System.device_base + 0x100024);
