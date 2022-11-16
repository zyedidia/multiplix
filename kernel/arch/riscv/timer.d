module kernel.arch.riscv.timer;

import core.volatile;

import kernel.arch.riscv.csr;
import sys = kernel.sys;

void timer_init() {
}

uint timer_cycles() {
    return cast(uint) csr_read!(Csr.mcycle)();
}

void timer_delay_us(uint us) {
    uint rb = timer_cycles();
    while (1) {
        uint ra = timer_cycles();
        if ((ra - rb) >= us * (sys.core_freq / (1000 * 1000))) {
            break;
        }
    }
}

struct clintImpl(uintptr base) {
    @property static ulong mtimecmp() {
        return volatileLoad(mtimecmp_addr());
    }

    @property static ulong mtimecmp(ulong val) {
        volatileStore(mtimecmp_addr(), val);
        return val;
    }

    @property static ulong mtime() {
        return volatileLoad(mtime_addr());
    }

    @property static ulong mtime(ulong val) {
        volatileStore(mtime_addr(), val);
        return val;
    }

    static ulong* mtimecmp_addr() {
        int hartid = cast(int) csr_read!(Csr.mhartid)();
        return cast(ulong*)(base + 0x4000 + 8 * hartid);
    }

    static ulong* mtime_addr() {
        return cast(ulong*)(base + 0xbff8);
    }
}

alias clint = clintImpl!(0x2000000);

extern (C) extern void timervec();

extern (C) __gshared ulong[5] timer_scratch;

void timer_irq_init() {
    int interval = 1000000;

    clint.mtimecmp = clint.mtime + interval;

    timer_scratch[3] = cast(ulong) clint.mtimecmp_addr();
    timer_scratch[4] = interval;
    csr_write!(Csr.mscratch)(cast(uintptr)&timer_scratch[0]);

    csr_write!(Csr.mtvec)(cast(uintptr)&timervec);
    // enable m-mode interrupts
    csr_write_bit!(Csr.mstatus)(Mstatus.mie, 1);
    // enable m-mode timer interrupts
    csr_write_bit!(Csr.mie)(Mie.mtie, 1);
}
