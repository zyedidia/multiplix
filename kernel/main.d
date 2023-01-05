module kernel.main;

import core.sync;

import io = ulib.io;

import kernel.board;
import kernel.timer;
import kernel.cpu;

import arch = kernel.arch;

__gshared bool primary = true;

extern (C) void kmain(int coreid) {
    if (primary) {
        primary = false;
        device_fence();
        arch.Cpu.start_all_cores();
    }

    Timer.delay_us(1000 * 100 * coreid);
    io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);

    if (coreid == System.ncores - 1) {
        Reboot.reboot();
    }
}
