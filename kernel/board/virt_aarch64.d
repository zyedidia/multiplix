module kernel.board.virt_aarch64;

import kernel.dev.uart.ns16550;
import kernel.dev.reboot.qsyscon;
import kernel.dev.emmc.unsupported;

import kernel.vm;

import sys = kernel.sys;

struct Machine {
    enum cpu_freq = 1 * 1000 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum ncores = 4;

    enum MemType : ubyte {
        normal = 0,
        device = 1,
    }

    struct MemRange {
        uintptr start;
        size_t sz;
        MemType type;
    }

    enum MemRange[1] mem_ranges = [
        MemRange(0, sys.gb!(4), MemType.normal),
    ];

    static MemType mem_type(uintptr pa) {
        foreach (r; mem_ranges) {
            if (pa >= r.start && pa < r.start + r.sz) {
                return r.type;
            }
        }
        return MemType.normal;
    }

    enum size_t memsize = sys.gb!(4);

    static void setup() {}
}

alias Uart = Ns16550!(pa2kpa(0x9000000));
alias Reboot = QemuSyscon!(pa2kpa(0x100000));
alias Emmc = UnsupportedEmmc;
