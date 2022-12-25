module kernel.board.virt_riscv64;

import kernel.dev.uart.ns16550;
import kernel.dev.reboot.qsyscon;

import sys = kernel.sys;

alias Uart = Ns16550!(0x10000000);
alias Reboot = QemuSyscon!(0x100000);

struct System {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);

    enum memsize_physical = sys.gb!(4);
}
