module kernel.arch.riscv.timer;

import core.volatile;

import kernel.arch.riscv.csr;
import sys = kernel.sys;

void init() {
}

uint cycles() {
    return cast(uint) read!(Reg.mcycle)();
}

void delay_us(uint us) {
    uint rb = cycles();
    while (1) {
        uint ra = cycles();
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
        int hartid = cast(int) read!(Reg.mhartid)();
        return cast(ulong*) (base + 0x4000 + 8*hartid);
    }
    static ulong* mtime_addr() {
        return cast(ulong*) (base + 0xbff8);
    }
}

alias clint = clintImpl!(0x2000000);

extern (C) extern void timervec();

extern (C) __gshared ulong[5] timer_scratch;

void irqinit() {
    int interval = 1000000;

    clint.mtimecmp = clint.mtime + interval;

    timer_scratch[3] = cast(ulong) clint.mtimecmp_addr();
    timer_scratch[4] = interval;
    write!(Reg.mscratch)(cast(uintptr) &timer_scratch[0]);

    write!(Reg.mtvec)(cast(uintptr) &timervec);
    // enable m-mode interrupts
    writeBit!(Reg.mstatus)(Mstatus.mie, 1);
    // enable m-mode timer interrupts
    writeBit!(Reg.mie)(Mie.mtie, 1);
}
