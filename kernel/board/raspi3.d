module kernel.board.raspi3;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;
import kernel.dev.timer.bcmcore;
import kernel.dev.mailbox.bcmmailbox;
import kernel.dev.emmc.bcm;

import kernel.vm;
import kernel.buddy;
import kernel.alloc;

import sys = kernel.sys;

struct System {
    enum gpu_freq = 250 * 1000 * 1000;
    enum ncores = 4;
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

    enum MemRange[] mem_ranges = [
        MemRange(0, sys.mb!(512), MemType.normal),
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

    alias Buddy = BuddyAllocator!(sys.pagesize, sys.mb!(512));
    __gshared Buddy buddy;

    alias allocator = buddy;
}

alias Uart = BcmMiniUart!(pa2kpa(System.device_base + 0x215000));
alias Gpio = BcmGpio!(pa2kpa(System.device_base + 0x200000));
alias Reboot = BcmReboot!(pa2kpa(System.device_base + 0x10001c), pa2kpa(System.device_base + 0x100024));
alias CoreTimer = BcmCoreTimer!(pa2kpa(0x4000_0000));
alias Mailbox = BcmMailbox!(pa2kpa(System.device_base + 0xb880));
alias Emmc = BcmEmmc!(pa2kpa(System.device_base + 0x00300000));
