module kernel.board.visionfive;

import kernel.dev.uart.dw8250;
import kernel.dev.gpio.jh7100;
import kernel.dev.reboot.unsupported;
import kernel.dev.irq.sfclint;
import kernel.dev.emmc.unsupported;

import kernel.vm;
import kernel.alloc;

import sys = kernel.sys;

struct Machine {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 2;

    enum mtime_freq = 6_250_000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange main_memory = MemRange(0x8000_0000, sys.gb!(2));

    enum MemRange[1] mem_ranges = [
        MemRange(0, sys.gb!(2)),
        main_memory,
    ];

    static void setup() {}
}

alias Uart = Dw8250!(pa2kpa(0x12440000));
alias Gpio = Jh7100Gpio!(pa2kpa(0x11910000));
alias Reboot = Unsupported;
alias Clint = SifiveClint!(pa2kpa(0x200_0000));
alias Emmc = UnsupportedEmmc;
