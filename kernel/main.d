module kernel.main;

import io = ulib.io;

import sys = kernel.sys;
import vm = kernel.vm;
import arch = kernel.arch.riscv64;

import kernel.cpu;
import kernel.spinlock;
import kernel.alloc;
import kernel.proc;

shared Spinlock bootlock;

auto hellobin = cast(immutable ubyte[]) import("user/hello/hello.bin");

void kmain(uintptr heapBase) {
    io.writeln("core ", cpuinfo.id, " booted, primary: ", cpuinfo.primary);

    if (!cpuinfo.primary) {
        bootlock.unlock();
        while (true) {
            arch.wait();
        }
    }
    io.writeln("hello rvos!");

    startAllCores();
    arch.Trap.init();
    arch.Trap.enable();
    arch.Timer.intr();
    kallocinit(heapBase);
    io.writeln("buddy kalloc returned: ", kallocpage().get());

    Proc p;
    if (!Proc.make(&p, hellobin, 0x1000, 0x1000)) {
        io.writeln("could not make process");
        return;
    }
    arch.usertrapret(&p, true);

    /* uint val = 1; */
    /* while (true) { */
    /*     arch.Timer.delayCycles(1000000000 / 2); */
    /*     sys.Gpio.write(0, val); */
    /*     val = !val; */
    /* } */
}

void startAllCores() {
    for (uint i = 0; i < numcpu; i++) {
        if (i == cpuinfo.id) {
            continue;
        }
        // bootlock will be unlocked when the core has reached kmain
        bootlock.lock();
        arch.startCore(i);
    }
}

extern (C) {
    void ulib_tx(ubyte b) {
        sys.Uart.tx(b);
    }

    void ulib_exit(ubyte code) {
        sys.Reboot.shutdown();
    }

    extern shared ubyte _kheap_start;

    void dstart(uint cpuid, uint ncpu, bool primary) {
        import kernel.init;

        if (primary) {
            // only zero the BSS for the primary core
            initBss();
            // set the immutable numcpu global
            cast(uint) numcpu = ncpu;
        }

        // tlsBase is heap + stack space allocated for each core
        uintptr tlsBase = cast(uintptr)&_kheap_start + 4096 * (ncpu + 1);
        size_t tlsSize = initTls(cpuid, tlsBase);

        cpuinfo.id = cpuid;
        cpuinfo.primary = primary;
        cpuinfo.tls = tlsBase + ncpu * tlsSize;
        cpuinfo.stack = cast(uintptr)&_kheap_start + 4096 * cpuid;

        sys.Uart.init();
        kmain(tlsBase + ncpu * tlsSize);
    }
}
