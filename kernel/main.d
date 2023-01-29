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

    /* lock.lock(); */
    /* io.writeln("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid); */
    /* lock.unlock(); */

    if (!cpuinfo.primary) {
        // spin secondary cores
        return;
    }

    Timer.delay_ms(100);

    import kernel.dev.mailbox.bcmmailbox;

    io.writeln("core clock: ", Mailbox.get_clock_rate(Mailbox.ClockType.core));
    io.writeln("emmc clock: ", Mailbox.get_clock_rate(Mailbox.ClockType.emmc));
    io.writeln("uart clock: ", Mailbox.get_clock_rate(Mailbox.ClockType.uart));
    io.writeln("arm clock:  ", Mailbox.get_clock_rate(Mailbox.ClockType.arm));

    io.writeln("i2c power state:");
    for (int i = 0; i < 3; i++) {
        bool on = Mailbox.get_domain_state(i);
        io.writeln("power domain status for ", i, " = ", on);
    }

    uint max_temp = Mailbox.get_max_temp();
    uint max_clock = Mailbox.get_max_clock_rate(Mailbox.ClockType.arm);
    while (1) {
        uint cur_temp = Mailbox.get_temp();
        io.writeln("cur temp: ", cur_temp, " max temp: ", max_temp);

        uint cur_clock = Mailbox.get_clock_rate(Mailbox.ClockType.arm);
        io.writeln("cur clock: ", cur_clock, " max clock: ", max_clock);

        if (cur_temp <= 50 && cur_clock < max_clock) {
            Mailbox.set_clock_rate(Mailbox.ClockType.arm, cur_clock + 100_000_000, false);
        }

        Timer.delay_ms(1000);
    }

    /* foreach (vamap; ptable.procs[0].pt.range()) { */
    /*     io.writeln(Hex(vamap.va), " ", Hex(vamap.pa), " ", vamap.user, " ", vamap.size); */
    /* } */
    /*  */
    /* enable_irq(); */
    /*  */
    /* schedule(); */
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
