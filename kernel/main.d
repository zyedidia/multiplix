module kernel.main;

import core.sync;

import io = ulib.io;

import kernel.board;
import kernel.timer;
import kernel.cpu;
import kernel.alloc;
import kernel.spinlock;
import kernel.proc;

import arch = kernel.arch;
import sys = kernel.sys;

shared Spinlock lock;

auto hello_elf = cast(immutable ubyte[]) import("user/hello/hello.elf");
__gshared Proc p;

extern (C) void kmain(int coreid, ubyte* heap) {
    arch.Trap.setup();

    if (cpuinfo.primary) {
        System.allocator.__ctor(cast(uintptr) heap);

        // boot up the other cores
        /* arch.Cpu.start_all_cores(); */
    }

    lock.lock();
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);
    lock.unlock();

    if (!cpuinfo.primary) {
        // spin secondary cores
        while (1) {}
    }

    import sbi = kernel.arch.riscv64.sbi;
    sbi.Debug.step_start();

    Timer.delay_nops(10);

    sbi.Debug.step_stop();

    if (!Proc.make(&p, hello_elf)) {
        io.writeln("could not initialize process");
        return;
    }

    arch.usertrapret(&p, true);
}

void irq() {
    version (raspi3) {
        CoreTimer.enable_irq();
    } else version (raspi4) {
        CoreTimer.enable_irq();
    }

    arch.Trap.setup();
    arch.Trap.enable();
    arch.Timer.intr();
}
