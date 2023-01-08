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

    /* KrAllocator kr = KrAllocator(heap, sys.mb!(128)); */
    /* void* p = kr.alloc(10); */
    /* io.writeln("allocated: ", p); */
    /*  */
    /* arch.Trap.init(); */
    /* arch.Trap.enable(); */
    /* arch.Timer.intr(); */
    /*  */
    /* while (1) {} */
    /*  */
    Reboot.reboot();
}
