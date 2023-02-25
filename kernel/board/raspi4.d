module kernel.board.raspi4;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;
import kernel.dev.timer.bcmcore;
import kernel.dev.mailbox.bcmmailbox;
import kernel.dev.emmc.bcm;

import kernel.vm;
import kernel.alloc;

import sys = kernel.sys;

struct Machine {
    enum gpu_freq = 250 * 1000 * 1000;
    enum ncores = 4;

    enum device_base = 0xfe000000;

    enum MemType : ubyte {
        normal = 0,
        device = 1,
    }

    struct MemRange {
        uintptr start;
        size_t sz;
        MemType type;
    }

    enum MemRange[] mem_ranges = [
        MemRange(0, sys.gb!(1), MemType.normal),
        MemRange(device_base, sys.mb!(28), MemType.device),
    ];

    static MemType mem_type(uintptr pa) {
        foreach (r; mem_ranges) {
            if (pa >= r.start && pa < r.start + r.sz) {
                return r.type;
            }
        }
        return MemType.normal;
    }

    enum size_t memsize = sys.gb!(1);

    static void setup() {
        version (kernel) {
            import kernel.cpu;
            if (cpuinfo.primary) {
                CoreTimer.enable_irq();

                // raise clock speed to max
                uint max_clock = Mailbox.get_max_clock_rate(Mailbox.ClockType.arm);
                Mailbox.set_clock_rate(Mailbox.ClockType.arm, max_clock, false);
                println("arm clock: ", Mailbox.get_clock_rate(Mailbox.ClockType.arm), " Hz");
                println("temp: ", Mailbox.get_temp());
            }
        }
    }
}

alias Uart = BcmMiniUart!(pa2kpa(Machine.device_base + 0x215000));
alias Gpio = BcmGpio!(pa2kpa(Machine.device_base + 0x200000));
alias Reboot = BcmReboot!(pa2kpa(Machine.device_base + 0x10001c), pa2kpa(Machine.device_base + 0x100024));
alias CoreTimer = BcmCoreTimer!(pa2kpa(0xff80_0000));
alias Mailbox = BcmMailbox!(pa2kpa(Machine.device_base + 0xb880));
alias Emmc = BcmEmmc!(pa2kpa(Machine.device_base + 0x00340000));
