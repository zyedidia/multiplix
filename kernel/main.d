module kernel.main;

import core.sync;

import io = ulib.io;

import kernel.board;
import kernel.timer;
import kernel.cpu;
import kernel.alloc;
import kernel.spinlock;
import kernel.proc;
import kernel.schedule;
import kernel.vm;

import arch = kernel.arch;
import sys = kernel.sys;

shared Spinlock lock;

auto hello_elf = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) void kmain(int coreid, ubyte* heap) {
    arch.Trap.setup();

    if (cpuinfo.primary) {
        System.allocator.construct(cast(uintptr) heap);

        if (!ptable.start(hello_elf)) {
            io.writeln("could not initialize process 0");
            return;
        }

        // boot up the other cores
        arch.Cpu.start_all_cores();
    }

    arch.setup();

    lock.lock();
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);
    lock.unlock();

    if (!cpuinfo.primary) {
        // spin secondary cores
        return;
    }

    Timer.delay_ms(100);

    foreach (vamap; ptable.procs[0].pt.range()) {
        io.writeln(Hex(vamap.va), " ", Hex(vamap.pa), " ", vamap.user, " ", vamap.size);
    }

    enable_irq();

    schedule();
}

void enable_irq() {
    version (raspi3) {
        CoreTimer.enable_irq();
    } else version (raspi4) {
        CoreTimer.enable_irq();
    }

    arch.Trap.enable();
    arch.Timer.intr();
}
