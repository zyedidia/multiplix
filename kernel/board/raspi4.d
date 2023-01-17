module kernel.board.raspi4;

import kernel.dev.uart.bcmmini;
import kernel.dev.gpio.bcm;
import kernel.dev.reboot.bcmreboot;
import kernel.dev.timer.bcmcore;

import kernel.vm;
import kernel.buddy;

import sys = kernel.sys;

struct System {
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

    alias Buddy = BuddyAllocator!(sys.pagesize, sys.gb!(1));
    __gshared Buddy allocator;
}

alias Uart = BcmMiniUart!(pa2kpa(System.device_base + 0x215000));
alias Gpio = BcmGpio!(pa2kpa(System.device_base + 0x200000));
alias Reboot = BcmReboot!(pa2kpa(System.device_base + 0x10001c), pa2kpa(System.device_base + 0x100024));
alias CoreTimer = BcmCoreTimer!(pa2kpa(0xff80_0000));
