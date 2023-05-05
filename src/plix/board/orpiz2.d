module plix.board.orpiz2;

import plix.dev.uart.dwapb : DwApbUart;
import plix.vm : pa2ka;
import sys = plix.sys;

struct Machine {
    enum ncores = 4;

    enum MemType : ubyte {
        normal = 0,
        device = 1,
    }

    struct MemRange {
        uintptr start;
        usize sz;
        MemType type;
    }

    enum MemRange main_memory = MemRange(0x4000_0000, sys.gb!(1), MemType.normal);

    enum MemRange[2] mem_ranges = [
        MemRange(0, sys.gb!(1), MemType.device),
        main_memory,
    ];

    static MemType mem_type(uintptr pa) {
        foreach (r; mem_ranges) {
            if (pa >= r.start && pa < r.start + r.sz) {
                return r.type;
            }
        }
        return MemType.normal;
    }
}

extern (C) extern __gshared ubyte _monitor_start, _heap_start;

__gshared DwApbUart uart;

void setup() {
    import plix.cpu : cpu;
    import plix.arch.aarch64.smc : cpu_on, affinity_info;
    import plix.arch.cache : sync_idmem;
    import config : ismonitor;

    uart = DwApbUart(pa2ka(0x500_0000));

    if (cpu.primary) {
        if (ismonitor()) {
            uart.setup(115200);

            sync_idmem(&_monitor_start, &_heap_start - &_monitor_start);
            for (int i = 1; i < Machine.ncores; i++) {
                cpu_on(i, cast(uintptr) 0x4100_0000, 0);
                while (affinity_info(i, 0) != 0) {
                }
            }
        }
    }
}
