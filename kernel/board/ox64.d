module kernel.board.ox64;

import kernel.dev.uart.bflb;
import kernel.dev.gpio.bflb;
import kernel.dev.reboot.bflb;
import kernel.dev.irq.bflbclint;
import kernel.dev.emmc.unsupported;

import kernel.vm;
import kernel.alloc;

import kernel.arch.riscv64.csr;

import core.volatile;
import core.sync;
import bits = ulib.bits;

import ulib.print;

// TODO: change this to the Ox64

import sys = kernel.sys;

struct Machine {
    enum cpu_freq = 480 * 1000 * 1000;
    enum cpu_freq_mhz = cpu_freq / (1000 * 1000);
    enum uart_freq = 80 * 1000 * 1000;
    enum ncores = 1;

    enum mtime_freq = 16_000_000;

    struct MemRange {
        uintptr start;
        size_t sz;
    }

    enum MemRange main_memory = MemRange(0x5000_0000, sys.mb!(64));
    enum MemRange all_memory = MemRange(0, sys.gb!(4));

    enum MemRange[1] mem_ranges = [all_memory];

    static void setup() {
    }

    import kernel.arch.riscv64.vm;

    static void fixup_pte(uintptr va, uintptr pa, size_t size, Pte* pte) {
        uintptr pa_end = pa + size;
        bool is_below = pa_end < main_memory.start;
        bool is_above = pa >= main_memory.start + main_memory.sz;
        if (is_below || is_above) {
            pte.data |= 1L << 63; // strongly ordered
        } else {
            pte.data |= 1L << 62; // cacheable
        }
    }
}

alias Uart = BouffaloLabsUart!(pa2kpa(0x2000A000));
alias Reboot = BouffaloLabsReboot!(pa2kpa(0x20000000), pa2kpa(0x30007000));
alias Clint = BouffaloLabsClint!(pa2kpa(0xE4000000));
alias Gpio = BouffaloLabsGpio!(pa2kpa(0x20000000));
alias UartMux = BouffaloLabsUartMux!(pa2kpa(0x20000000));
alias Emmc = UnsupportedEmmc;
