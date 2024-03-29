module plix.board.visionfive;

import plix.dev.uart.dwapb : DwApbUart;
import plix.dev.irq.clint : Clint;
import plix.vm : pa2ka;
import sys = plix.sys;

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

    enum MemRange[2] mem_ranges = [
        MemRange(0, sys.gb!(2)),
        main_memory,
    ];
}

__gshared DwApbUart uart;
__gshared Clint clint;

void setup() {
    uart = DwApbUart(pa2ka(0x12440000));
    clint = Clint(pa2ka(0x200_0000));
}
