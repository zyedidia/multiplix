module kernel.board.raspi4;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;
import kernel.dev.timer.bcmcore;

import kernel.vm;

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

alias Uart = BcmMiniUart!(pa2kpa(System.device_base + 0x215000));
alias Gpio = BcmGpio!(pa2kpa(System.device_base + 0x200000));
alias Reboot = BcmReboot!(pa2kpa(System.device_base + 0x10001c), pa2kpa(System.device_base + 0x100024));
alias CoreTimer = BcmCoreTimer!(pa2kpa(0xff80_0000));
