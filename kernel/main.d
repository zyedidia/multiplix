module kernel.main;

import io = ulib.io;

import sys = kernel.sys;
import vm = kernel.vm;
import arch = kernel.arch.riscv64;

import sbi = kernel.arch.riscv64.sbi;

import kernel.cpu;
import kernel.spinlock;
import kernel.alloc;
import kernel.proc;

shared Spinlock bootlock;

auto helloelf = cast(immutable ubyte[]) import("user/hello/hello.elf");

__gshared Proc p;

extern (C) {
    extern __gshared ubyte _kcode_start, _kcode_end;
}

void kmain(uintptr heapBase) {
    io.writeln("core ", cpuinfo.id, " booted, primary: ", cpuinfo.primary);

    if (!cpuinfo.primary) {
        bootlock.unlock();
        while (true) {
            arch.wait();
        }
    }

    /* sbi.Step.enable(); */

    io.writeln("hello rvos!");

    /* startAllCores(); */
    import kernel.arch.riscv64.csr;
    auto instret = Csr.instret;
    auto cycle = Csr.cycle;
    kallocinit(heapBase);
    /* auto fw_heap = kallocpage(1024 * 1024 * 16).get(); */
    /* sbi.Step.setHeap(cast(void*)vm.ka2pa(cast(uintptr)fw_heap), 1024 * 1024); */

    sbi.Step.markRegion(&_kcode_start, &_kcode_end - &_kcode_start, sbi.Step.Region.rdonly);

    import ulib.memory;
    sbi.Step.enable(sbi.Step.Check.region);
    /* memset(&kmain, 0, 1234); */
    sbi.Step.disable();

    io.writeln("buddy kalloc returned: ", kallocpage().get());

    io.writeln("instructions ", Csr.instret - instret, " cycles ", Csr.cycle - cycle);

    auto mem = kallocpage.get();
    sbi.Step.enable(sbi.Step.Check.mem);
    memset(mem, 0, 4097);
    sbi.Step.disable();


    /* arch.Trap.init(); */
    /* arch.Trap.enable(); */
    /* arch.Timer.intr(); */

    sbi.Step.enable(sbi.Step.Check.vmafence);
    if (!Proc.make(&p, helloelf)) {
        io.writeln("could not make process");
        return;
    }
    arch.usertrapret(&p, true);
    sbi.Step.disable();

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
        cpuinfo.tls = tlsBase + cpuid * tlsSize;
        cpuinfo.stack = cast(uintptr)&_kheap_start + 4096 * cpuid;

        sys.Uart.init();
        kmain(tlsBase + ncpu * tlsSize);
    }
}
