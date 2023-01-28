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

    for (int i = 0; i < 10; i++) {
        /* arch.Debug.step_start(); */
        auto time = Timer.time_fn!(10)(() {
            static foreach (i; 1 .. 1000) {
                asm {
                    "nop";
                }
            }
        });
        /* arch.Debug.step_stop(); */
        io.writeln(time);
    }

    for (int i = 0; i < 10; i++) {
        io.writeln(Timer.time_fn!(10)(() {
            static foreach (i; 1 .. 1000) {
                asm {
                    "nop";
                }
            }
        }));
    }

    import ldc.llvmasm;
    version (AArch64) {
        import kernel.arch.aarch64.sysreg;
        foreach (i; 0 .. 20) {
            __asm("svc 0", "{x0},~{x1}", SysReg.pmccntr_el0);
        }
        SysReg.pmuserenr_el0 = 1;
    } else version (RISCV64) {
        /* import kernel.arch.riscv64.csr; */
        /* foreach (i; 0 .. 20) { */
        /*     __asm("ecall", "{a0},~{a1}", Csr.cycle); */
        /* } */
    }
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
