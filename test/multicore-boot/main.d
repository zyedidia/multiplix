module kernel.main;

import core.sync;

import kernel.spinlock;
import kernel.board;
import kernel.timer;
import kernel.cpu;

import arch = kernel.arch;
import sys = kernel.sys;

shared Spinlock lock;
shared int x;

extern (C) void kmain(int coreid, ubyte* heap) {
    if (cpuinfo.primary) {
        // boot up the other cores
        arch.Cpu.start_all_cores();
    }

    lock.lock();
    (cast() x)++;
    lock.unlock();

    if (cpuinfo.primary) {
        Timer.delay_ms(10);
        assert(x == System.ncores);
        println("multicore-boot: PASS");
        Reboot.shutdown();
    }
}
