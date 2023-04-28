module plix.board.raspi3;

import plix.dev.uart.bcmmini : BcmMiniUart;
import plix.dev.gpio.bcm : BcmGpio;
import sys = plix.sys;

struct machine {
    enum ncores = 4;
    enum gpu_freq = 250 * 1000 * 1000;
    enum device_base = 0x3f000000;

    enum MemType : ubyte {
        normal = 0,
        device = 1,
    }

    struct MemRange {
        uintptr start;
        size_t sz;
        MemType type;
    }

    enum MemRange main_memory = MemRange(0x0, sys.mb!(512), MemType.normal);

    enum MemRange[2] mem_ranges = [
        main_memory,
        MemRange(device_base, sys.mb!(18), MemType.device),
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

__gshared BcmGpio gpio = BcmGpio(machine.device_base + 0x200000);
__gshared BcmMiniUart uart = BcmMiniUart(machine.device_base + 0x215000);

void setup() {
    uart.setup(115200, machine.gpu_freq, gpio);
}
