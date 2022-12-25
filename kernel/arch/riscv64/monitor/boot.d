module kernel.arch.riscv64.monitor.boot;

import kernel.arch.riscv64.csr;

import bits = ulib.bits;

extern (C) extern __gshared ubyte _smode_entrypoint;

void enter_smode() {
    // We want 'mret' to jump to _smode_entrypoint, so we write it to mepc.
    Csr.mepc = cast(uintptr) &_smode_entrypoint;
    // Write S-mode to mstatus.MPP.
    Csr.mstatus = bits.write(Csr.mstatus, 12, 11, Priv.s);
    // Disable paging.
    Csr.satp = 0;
    // Delegate certain interrupts and exceptions.
    Csr.medeleg = 0x00f0b509;
    Csr.mideleg = 0x00001666;

    // Configure the PMP to allow all accesses for S-mode.
    // TOR region allowing R/W/X starting at 0x0 and ending at
    // 0xffff_ffff_ffff.
    Csr.pmpcfg0 = 0b0_0_01_111;
    Csr.pmpaddr0 = 0xffff_ffff_ffff;

    asm {
        // perform the switch and jump to _smode_entrypoint
        "mret";
        "_smode_entrypoint:";
    }
}
