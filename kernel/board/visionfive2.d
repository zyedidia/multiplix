module kernel.board.visionfive;

import kernel.dev.uart.dw8250;
import kernel.dev.gpio.starfive;
import kernel.dev.reboot.unsupported;
import kernel.dev.irq.sfclint;

import kernel.vm;

import sys = kernel.sys;

struct System {
    enum cpu_freq = 1 * 1000 * 1000 * 1000 + 5 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 5;

    enum mtime_freq = 6_250_000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange device = MemRange(0, sys.gb!(1));
    enum MemRange mem = MemRange(sys.gb!(1), sys.gb!(2));

    alias Buddy = BuddyAllocator!(sys.pagesize, sys.gb!(3));
    static __gshared Buddy allocator;
}

alias Uart = Dw8250!(pa2kpa(0x10000000));
alias Reboot = Unsupported;
alias Clint = SifiveClint!(pa2kpa(0x200_0000));
