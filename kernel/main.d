module kernel.main;

import io = ulib.io;

import sys = kernel.sys;
import arch = kernel.arch.riscv64;

import kernel.cpu;
import kernel.alloc;

void kmain(uintptr heapBase) {
    io.writeln("core: ", cpuinfo.id, ", primary: ", cpuinfo.primary);

    if (!cpuinfo.primary) {
        while (true) {
            arch.wait();
        }
    }
    import kernel.arch.riscv64.sbi;
    io.writeln("status (should be 0): ", Hart.getStatus(cpuinfo.id));

    io.writeln("hello rvos!");

    import bits = ulib.bits;
    sys.Uart.flushTx();
    io.writeln(bits.get(sys.Uart.lsr, sys.Uart.Lsr.thre));
    sys.Uart.flushTx();
    io.writeln(bits.get(sys.Uart.lsr, sys.Uart.Lsr.temt));

    /* arch.startAllCores(); */
    /* arch.Trap.init(); */
    /* arch.Trap.enable(); */
    /* arch.Timer.intr(); */
    /* kallocinit(heapBase); */
    /* io.writeln("buddy kalloc returned: ", kallocpage()); */

    uint val = 1;
    while (true) {
        arch.Timer.delayCycles(1000000000/2);
        sys.Gpio.write(0, val);
        val = !val;
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
        }

        uintptr tlsBase = cast(uintptr) &_kheap_start;
        size_t tlsSize = initTls(cpuid, tlsBase);

        cpuinfo.id = cpuid;
        cpuinfo.primary = primary;

        sys.Uart.init();
        kmain(tlsBase + ncpu * tlsSize);
    }
}
