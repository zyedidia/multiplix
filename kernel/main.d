module kernel.main;

import io = ulib.io;

import sys = kernel.sys;
import kernel.alloc;
import arch = kernel.arch.riscv64;

void kmain(uintptr heapBase) {
    io.writeln("hello rvos!");

    arch.Trap.init();
    arch.Trap.enable();
    arch.Timer.intr();
    kallocinit(heapBase);
    io.writeln("buddy kalloc returned: ", kallocpage());

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

    void dstart(uint cpuid, uint ncpu) {
        import kernel.init;

        initBss();

        uintptr tlsBase = cast(uintptr) &_kheap_start;
        size_t tlsSize = initTls(cpuid, tlsBase);

        kmain(tlsBase + ncpu * tlsSize);
    }
}
