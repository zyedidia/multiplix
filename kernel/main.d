module kernel.main;

import kernel.spinlock;

immutable ubyte[] hello_elf = cast(immutable ubyte[]) import("user/hello/hello.elf");

shared Spinlock lock;

extern (C) void kmain(int coreid, ubyte* heap) {
    import arch = kernel.arch;
    import sys = kernel.sys;
    import kernel.cpu;
    import kernel.schedule;

    arch.ArchTrap.setup();

    if (cpuinfo.primary) {
        sys.allocator.construct(cast(uintptr) heap);

        // reallocate the hello ELF to make sure it is aligned properly
        import kernel.alloc;
        ubyte* hello = cast(ubyte*) kalloc(hello_elf.length);
        assert(hello);
        import ulib.memory;
        memcpy(hello, hello_elf.ptr, hello_elf.length);

        if (!runq.start(hello[0 .. hello_elf.length])) {
            println("could not initialize hello.elf");
            return;
        }

        arch.Cpu.start_all_cores();
    }

    arch.setup();

    lock.lock();
    println("entered kmain at: ", &kmain, " core: ", cpuinfo.coreid);
    lock.unlock();

    import kernel.arch;
    // start generating timer interrupts
    ArchTimer.intr();

    scheduler();
}
