module kernel.board.raspi4;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;

import sys = kernel.sys;

struct System {
    enum gpu_freq = 250 * 1000 * 1000;
    enum ncores = 4;

    enum device_base = 0xfe000000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange mem = MemRange(0, sys.gb!(2));
    /* enum MemRange mem2 = MemRange(sys.gb!(4), sys.gb!(10)); */
    enum MemRange device = MemRange(device_base, sys.gb!(1));
}

alias Uart = BcmMiniUart!(System.device_base + 0x215000);
alias Gpio = BcmGpio!(System.device_base + 0x200000);
alias Reboot = BcmReboot!(System.device_base + 0x10001c, System.device_base + 0x100024);
