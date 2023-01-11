module kernel.main;

import core.sync;

import io = ulib.io;

import kernel.board;
import kernel.timer;
import kernel.cpu;
import kernel.alloc;
import kernel.spinlock;

import arch = kernel.arch;
import sys = kernel.sys;

shared Spinlock lock;

extern (C) void kmain(int coreid, ubyte* heap) {
    if (cpuinfo.primary) {
        // boot up the other cores
        arch.Cpu.start_all_cores();
    }

    lock.lock();
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);
    lock.unlock();

    /* version (raspi3) { */
    /*     CoreTimer.enable_irq(); */
    /* } else version (raspi4) { */
    /*     CoreTimer.enable_irq(); */
    /* } */
    /*  */
    /* arch.Trap.init(); */
    /* arch.Trap.enable(); */
    /* arch.Timer.intr(); */
    /*  */
    Timer.delay_ms(500);
    /*  */
    /* io.writeln("done"); */

    if (cpuinfo.primary) {
        io.writeln("done");
        Reboot.reboot();
    }
}
