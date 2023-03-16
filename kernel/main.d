module kernel.main;

import kernel.spinlock;

immutable ubyte[] hello_elf = cast(immutable ubyte[]) import("user/hello/hello.elf");

shared Spinlock lock;

import arch = kernel.arch;

// Pagetable used by the kernel scheduler.
__gshared arch.Pagetable kernel_pagetable;

extern (C) void kmain(int coreid, ubyte* heap) {
    import sys = kernel.sys;
    import kernel.cpu;
    import kernel.schedule;
    import ulib.print;

    arch.ArchTrap.setup();

    if (cpu.primary) {
        enum monitor_heap = sys.mb!(1);

        version (sanitizer) {
            import kernel.board;
            import kernel.sanitizer;
            ubyte[] asan_pages = heap[0 .. Machine.main_memory.sz / 2];
            heap += Machine.main_memory.sz / 2;
            asan.setup(asan_pages, cast(uintptr) heap + monitor_heap, Machine.main_memory.sz / 2);

            arch.Debug.alloc_heap(heap, monitor_heap);
            heap += monitor_heap;
        }

        // Allocate a heap for the monitor (the monitor checkers allocate
        // memory).

        // Initialize the system allocator.
        sys.allocator.construct(cast(uintptr) heap);

        version (check) {
            arch.Debug.enable();
        }

        // Reallocate the hello ELF to make sure it is aligned properly.
        import kernel.alloc;

        ubyte* hello = cast(ubyte*) kalloc(hello_elf.length);
        assert(hello);
        import libc;
        memcpy(hello, hello_elf.ptr, hello_elf.length);

        // Initialize the hello process.
        if (!runq.start(hello[0 .. hello_elf.length])) {
            println("could not initialize hello.elf");
            return;
        }

        // Map the kernel into the kernel pagetable.
        arch.kernel_procmap(&kernel_pagetable);

        // Run unit tests if they exist.
        import test = kernel.test;
        test.run_all();

        // Initialize all cores.
        arch.Cpu.start_all_cores();
    } else {
        version (check) {
            arch.Debug.enable();
        }
    }

    // Switch to the kernel pagetable (from the early boot pagetable). The main
    // difference between this pagetable and the boot pagetable is that in this
    // pagetable, nothing is mapped in the lower half of the address space.
    arch.kernel_ptswitch(&kernel_pagetable);

    // Any architecture-specific setup, such as enabling VM/caches in the
    // monitor and enabling the cycle counter (aarch64).
    arch.setup();

    lock.lock();
    println("entered kmain at: ", &kmain, " core: ", cpu.coreid);
    lock.unlock();

    import kernel.timer;
    Timer.delay_ms(50);

    import kernel.arch;
    // Start generating timer interrupts.
    ArchTimer.intr();

    // Enter the scheduler.
    scheduler();
}
