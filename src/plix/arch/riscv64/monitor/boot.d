module plix.arch.riscv64.monitor.boot;

import plix.arch.riscv64.csr : Csr, Priv;
import plix.arch.riscv64.regs : rdtp, rdgp;
import plix.board : Machine;

import bits = core.bits;

extern (C) void _enter_smode();

void enter_smode() {
    // Write S-mode to mstatus.MPP.
    Csr.mstatus = bits.write(Csr.mstatus, 12, 11, Priv.s);

    // Disable paging.
    Csr.satp = 0;
    // Delegate certain interrupts and exceptions.
    Csr.medeleg = 0x00f0b501;
    Csr.mideleg = 0x00001666;

    // Configure the PMP to allow all accesses for S-mode.
    // TOR region allowing R/W/X starting at 0x0 and ending at
    // 0xffff_ffff_ffff.
    Csr.pmpcfg0 = 0b0_0_01_111;
    Csr.pmpaddr0 = 0xffff_ffff_ffff;

    // Call asm function that performs actual transition.
    _enter_smode();
}

void enter_kmode() {
    enter_smode();
}

extern (C) extern void monitorvec();
extern (C) extern __gshared ubyte _heap_start;

struct ScratchFrame {
    uintptr sp;
    uintptr tp;
    uintptr gp;
    uintptr trap_sp;
}

__gshared ScratchFrame[Machine.ncores] frames;

void monitor_init() {
    Csr.mtvec = cast(uintptr) &monitorvec;
    Csr.mcounteren = 0b111;

    auto id = Csr.mhartid;
    frames[id] = ScratchFrame(cast(uintptr) &_heap_start + 4096 * (id + 1), rdtp(), rdgp(), 0);
    Csr.mscratch = cast(uintptr) &frames[id];
}
