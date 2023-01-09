module kernel.board.visionfive;

import kernel.dev.uart.dw8250;
import kernel.dev.gpio.starfive;
import kernel.dev.reboot.unsupported;

import kernel.vm;

import sys = kernel.sys;

struct System {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 2;

    enum mtime_freq = 6_250_000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange device = MemRange(0, sys.gb!(2));
    enum MemRange mem = MemRange(sys.gb!(2), sys.gb!(2));
}

alias Uart = Dw8250!(pa2kpa(0x12440000));
alias Gpio = StarfiveGpio!(pa2kpa(0x11910000));
alias Reboot = Unsupported;
