module plix.board.raspi3;

import plix.dev.uart.bcmmini : BcmMiniUart;
import plix.dev.gpio.bcm : BcmGpio;
import plix.dev.timer.bcmcore : BcmCoreTimer;
import plix.dev.mailbox.bcm : BcmMailbox;
import sys = plix.sys;

struct Machine {
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

__gshared BcmGpio gpio = BcmGpio(Machine.device_base + 0x200000);
__gshared BcmMiniUart uart = BcmMiniUart(Machine.device_base + 0x215000);
__gshared BcmCoreTimer timer = BcmCoreTimer(0x4000_0000);
__gshared BcmMailbox mailbox = BcmMailbox(Machine.device_base + 0xb880);

void setup() {
    import plix.cpu : cpu;
    import plix.print;

    uart.setup(115200, Machine.gpu_freq, gpio);

    if (cpu.primary) {
        // Raise clock speed to the max.
        uint max = mailbox.get_max_clock_rate(BcmMailbox.ClockType.arm);
        mailbox.set_clock_rate(BcmMailbox.ClockType.arm, max, false);

        printf("arm clock: %d Hz\n", mailbox.get_clock_rate(BcmMailbox.ClockType.arm));
        printf("temp: %d C\n", mailbox.get_temp());
    }

    timer.enable_irq();
}
