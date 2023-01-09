module kernel.main;

import core.sync;

import io = ulib.io;

import kernel.board;
import kernel.timer;
import kernel.cpu;
import kernel.alloc;

import arch = kernel.arch;
import sys = kernel.sys;

__gshared bool primary = true;

extern (C) void kmain(int coreid, ubyte* heap) {
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);

    KrAllocator kr = KrAllocator(heap, sys.mb!(128));
    void* p = kr.alloc(10);
    io.writeln("allocated: ", p);

    arch.Trap.init();
    arch.Trap.enable();

    import core.volatile;
    ulong rdtime() {
        uint ls32 = volatile_ld(cast(uint*) 0x4000_001C);
        uint ms32 = volatile_ld(cast(uint*) 0x4000_0020);
        return ((cast(ulong)ms32) << 32) | ls32;
    }
    volatile_st(cast(uint*) 0x4000_0040, 0b0010);

    asm {
        "msr cntp_ctl_el0, %0" :: "r"(1);
        "msr cntp_tval_el0, %0" :: "r"(1000);
    }

    Timer.delay_nops(1000000000);

    io.writeln("done");

    /* auto start = rdtime(); */
    /* Timer.delay_us(10000); */
    /* io.writeln(rdtime() - start); */
    /* Timer.delay_us(1000000); */

    /* arch.Timer.intr(); */

    Reboot.reboot();
}
