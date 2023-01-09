module kernel.board.raspi3;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;

import kernel.vm;

import sys = kernel.sys;

struct System {
    enum gpu_freq = 250 * 1000 * 1000;
    enum ncores = 4;
    enum device_base = 0x3f000000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange mem = MemRange(0, sys.gb!(1));
    enum MemRange device = MemRange(sys.gb!(1), sys.gb!(1));
}

alias Uart = BcmMiniUart!(pa2kpa(System.device_base + 0x215000));
alias Gpio = BcmGpio!(pa2kpa(System.device_base + 0x200000));
alias Reboot = BcmReboot!(pa2kpa(System.device_base + 0x10001c), pa2kpa(System.device_base + 0x100024));
