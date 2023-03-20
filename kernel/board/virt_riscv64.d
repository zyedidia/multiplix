module kernel.board.virt_riscv64;

import kernel.dev.uart.ns16550;
import kernel.dev.reboot.qsyscon;
import kernel.dev.irq.sfclint;
import kernel.dev.emmc.unsupported;

import kernel.vm;

import sys = kernel.sys;

struct Machine {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 4;

    // best guess for qemu
    enum mtime_freq = 3_580_000 * 2;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange main_memory = MemRange(0x8000_0000, sys.gb!(2));

    enum MemRange[2] mem_ranges = [
        MemRange(0, sys.gb!(2)),
        main_memory,
    ];

    static void setup() {}
}

alias Uart = Ns16550!(pa2ka(0x10000000));
alias Reboot = QemuSyscon!(pa2ka(0x100000));
alias Clint = SifiveClint!(pa2ka(0x200_0000));
alias Emmc = UnsupportedEmmc;
