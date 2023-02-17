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
import kernel.fs.console;

import arch = kernel.arch;
import sys = kernel.sys;

shared Spinlock lock;

immutable ubyte[] hello_elf = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) void kmain(int coreid, ubyte* heap) {
    arch.Trap.setup();

    if (cpuinfo.primary) {
        sys.allocator.construct(cast(uintptr) heap);

        Console.setup();

        if (!runq.start(hello_elf)) {
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

    // static if (is(typeof(Emmc.setup))) {
    //     assert(Emmc.setup());
    //     import kernel.fs.fat32.fat32;
    //     Fat32FS fat;
    //     assert(fat.setup());
    //     FileRange files = fat.readdir(fat.root());
    //     foreach (file; files) {
    //         io.writeln(file.name);
    //         ubyte[] data = fat.readfile(file.id(), file.size());
    //         io.writeln(data.length);
    //         import ulib.crc32;
    //         io.writeln("crc: ", Hex(crc32(data.ptr, data.length)));
    //         file.destroy();
    //     }
    // }
    //
    // Reboot.reboot();

    // Console.stdout.vnode.write(Console.stdout, cast(Proc*) null, cast(ubyte[]) "hello world");

    enable_irq();
    schedule();
}

void enable_irq() {
    arch.Trap.enable();
    arch.Timer.intr();
}
