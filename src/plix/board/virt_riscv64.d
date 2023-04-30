module plix.board.virt_riscv64;

import plix.dev.uart.virt : Virt;
import plix.dev.irq.clint : Clint;
import plix.dev.reboot.qsyscon : QemuSyscon;
import sys = plix.sys;

struct Machine {
    enum ncores = 4;
    enum mtime_freq = 3_580_000 * 2;

    struct MemRange {
        uintptr start;
        usize sz;
    }

    enum MemRange main_memory = MemRange(0x8000_0000, sys.gb!(2));

    enum MemRange[2] mem_ranges = [
        MemRange(0, sys.gb!(2)),
        main_memory,
    ];
}

__gshared Virt uart = Virt(cast(Virt.Regs*) 0x1000_0000);
__gshared Clint clint = Clint(0x200_0000);
__gshared QemuSyscon reboot = QemuSyscon(0x10_0000);

void setup() {}
