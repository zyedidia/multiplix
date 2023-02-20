module kernel.board.visionfive2;

import kernel.dev.uart.dw8250;
import kernel.dev.gpio.jh7110;
import kernel.dev.reboot.unsupported;
import kernel.dev.irq.sfclint;
import kernel.dev.emmc.unsupported;

import kernel.vm;
import kernel.alloc;

import sys = kernel.sys;

struct Machine {
    enum cpu_freq = 1 * 1000 * 1000 * 1000 + 5 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 5;

    enum mtime_freq = 6_250_000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange[] mem_ranges = [
        MemRange(0, sys.gb!(4)),
    ];

    enum size_t memsize = sys.gb!(3);

    static void setup() {}
}

alias Uart = Dw8250!(pa2kpa(0x10000000));
alias Gpio = Jh7110Gpio!(pa2kpa(0x13040000));
alias Reboot = Unsupported;
alias Clint = SifiveClint!(pa2kpa(0x200_0000));
alias Emmc = UnsupportedEmmc;
