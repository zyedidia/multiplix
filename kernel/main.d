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

__gshared KrAllocator kr;

extern (C) void kmain(int coreid, ubyte* heap) {
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);
    if (primary) {
        kr = KrAllocator(heap, sys.mb!(128));
        arch.kernel_setup_alloc(true, &kr);
        // boot up the other cores
        /* primary = false; */
        /* arch.Cpu.start_all_cores(); */
    } else {
        arch.kernel_setup_alloc(false, &kr);
    }

    version (raspi3) {
        CoreTimer.enable_irq();
    } else version (raspi4) {
        CoreTimer.enable_irq();
    }

    arch.Trap.init();
    arch.Trap.enable();
    arch.Timer.intr();

    Timer.delay_ms(2000);

    io.writeln("done");

    Reboot.reboot();
}
