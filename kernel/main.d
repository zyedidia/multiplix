module kernel.main;

import kernel.spinlock;

immutable ubyte[] hello_elf = cast(immutable ubyte[]) import("user/hello/hello.elf");

shared Spinlock lock;

import arch = kernel.arch;

__gshared arch.Pagetable kernel_pagetable;

extern (C) void kmain(int coreid, ubyte* heap) {
    import sys = kernel.sys;
    import kernel.cpu;
    import kernel.schedule;
    import ulib.print;

    arch.ArchTrap.setup();

    if (cpu.primary) {
        enum monitor_heap = sys.mb!(64);
        arch.Debug.alloc_heap(heap, monitor_heap);
        heap += monitor_heap;

        sys.allocator.construct(cast(uintptr) heap);

        version (check) {
            arch.Debug.enable();
        }

        // reallocate the hello ELF to make sure it is aligned properly
        import kernel.alloc;
        ubyte* hello = cast(ubyte*) kalloc(hello_elf.length);
        assert(hello);
        import libc;
        memcpy(hello, hello_elf.ptr, hello_elf.length);

        if (!runq.start(hello[0 .. hello_elf.length])) {
            println("could not initialize hello.elf");
            return;
        }

        arch.kernel_procmap(&kernel_pagetable);

        // run unit tests if they exist
        import test = kernel.test;
        test.run_all();

        arch.Cpu.start_all_cores();
    } else {
        version (check) {
            arch.Debug.enable();
        }
    }

    arch.kernel_ptswitch(&kernel_pagetable);

    arch.setup();

    lock.lock();
    println("entered kmain at: ", &kmain, " core: ", cpu.coreid);
    lock.unlock();

    import kernel.timer;
    Timer.delay_ms(50);

    import kernel.arch;
    // start generating timer interrupts
    ArchTimer.intr();

    scheduler();
}
