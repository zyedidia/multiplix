module kernel.main;

import core.volatile;

import dev = kernel.board.virt.dev;
import arch = kernel.arch.riscv;
import sbi = kernel.arch.riscv.sbi;

import vm = kernel.vm;
import sys = kernel.sys;
import kernel.alloc;

import io = ulib.io;
import ulib.linker;

// The bootloader drops us in here with an identity-mapped pagetable.
void kmain(uint hartid, uint nharts, uintptr heap_start) {
    if (!sbi.Base.probe_extension(sbi.Timer.ext)) {
        io.writeln("timer extension not supported!");
        ulib_exit(1);
    }
    io.writeln("kmain(", hartid, ", ", nharts, ", ", cast(void*) heap_start, ")");

    arch.timer_irq_init();
    arch.trap_init();
    arch.trap_enable();
    io.writeln("timer interrupts enabled");
    kallocinit(heap_start);
    io.writeln("buddy kalloc returned: ", kalloc_page());

    while (true) {
        asm {
            "wfi";
        }
    }
}

extern (C) {
    void ulib_tx(ubyte b) {
        sbi.legacy_putchar(b);
        /* dev.Uart.tx(b); */
    }

    void ulib_exit(ubyte code) {
        sbi.Reset.shutdown();
        /* dev.SysCon.shutdown(); */
    }
}
