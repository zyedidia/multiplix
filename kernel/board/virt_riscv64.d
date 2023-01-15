module kernel.board.virt_riscv64;

import kernel.dev.uart.ns16550;
import kernel.dev.reboot.qsyscon;
import kernel.dev.irq.sfclint;

import kernel.vm;
import kernel.buddy;

import sys = kernel.sys;

struct System {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 4;

    // best guess for qemu
    enum mtime_freq = 3_580_000 * 2;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange device = MemRange(0, sys.gb!(2));
    enum MemRange mem = MemRange(sys.gb!(2), sys.gb!(4));

    alias Buddy = BuddyAllocator!(sys.pagesize, sys.gb!(4));
    static __gshared Buddy allocator;
}

alias Uart = Ns16550!(pa2kpa(0x10000000));
alias Reboot = QemuSyscon!(pa2kpa(0x100000));
alias Clint = SifiveClint!(pa2kpa(0x200_0000));
