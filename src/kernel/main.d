module kernel.main;

import plix.print : printf, println;
import plix.fwi : wakeup_cores;
import plix.timer : Timer;
import plix.alloc : kallocinit, kalloc, kfree;
import plix.proc : Proc;
import plix.schedule : runq, schedule;
import plix.arch.trap : Irq;

import plix.sys : mb;

immutable ubyte[] hello_data = cast(immutable ubyte[]) import("user/hello/hello.elf");

extern (C) extern __gshared ubyte _heap_start;

import plix.arch.vm : Pagetable, PtLevel;
import plix.vm : Perm;
import plix.arch.riscv64.csr : Csr;
import plix.arch.cache : vm_fence;
import plix.arch.boot : kernel_procmap;

__gshared Pagetable pagetable;

extern (C) void kmain(uint coreid, bool primary) {
    kallocinit(&_heap_start, mb!(512));
    kernel_procmap(&pagetable);
    Csr.satp = pagetable.satp(0);
    vm_fence();

    printf("benchmarking...\n");

    benchmarks();

    // if (primary) {
    //     wakeup_cores();
    // }
    //
    // printf("core: %u, entered kmain at: %p\n", coreid, &kmain);
    //
    // if (!primary) {
    //     return;
    // }
    //
    // kallocinit(&_heap_start, mb!(512));
    //
    // ubyte[] hello = kalloc(hello_data.length);
    // ensure(hello != null);
    // import builtins : memcpy;
    // memcpy(hello.ptr, hello_data.ptr, hello.length);
    //
    // for (int i = 0; i < 1; i++) {
    //     Proc* proc = Proc.make_from_elf(hello);
    //     ensure(proc != null);
    //     runq.push_front(proc);
    //
    //     import plix.vm : PtIter;
    //     PtIter iter = PtIter.get(proc.pt);
    //     foreach (ref map; iter) {
    //         printf("%lx -> %lx\n", map.va, map.pa);
    //     }
    // }
    //
    // Timer.intr(Timer.time_slice);
    // Irq.on();
    //
    // schedule();
}

void benchmarks() {
    tlb_miss_individual();
}

void load_satp() {
    uintptr satp = Csr.satp;

    enum n = 1000;
    auto start = Timer.cycles();
    static foreach (j; 0 .. n) {
        Csr.satp = satp;
    }
    auto end = Timer.cycles();
    printf("load_satp: %ld\n", (end - start) / n);
}

void sfence() {
    auto time = Timer.time_fn!(1000)(function() {
        asm {
            "sfence.vma";
        }
    });
    printf("sfence: %ld\n", time);
}

extern (C) void empty();

void func_call_ret() {
    auto time = Timer.time_fn!(1000)(function() {
        empty();
    });
    printf("func_call_ret: %ld\n", time);
}

void m_mode_ret() {
    import plix.fwi : install_empty_handler;
    install_empty_handler();
    auto time = Timer.time_fn!(1000)(function() {
        asm {
            "ecall";
        }
    });
    printf("m_mode_ret: %ld\n", time);
}

void m_mode() {
    import plix.fwi : install_time_handler;
    install_time_handler();

    usize bench() {
        import gcc.attributes;
        @register("a0") usize count;
        asm {
            "rdcycle %0" : "=r"(count);
            "ecall" : "+r"(count);
        }
        return count;
    }
    for (int i = 0; i < 10; i++) {
        printf("m_mode: %ld\n", bench());
    }
}

void watchpoint() {
    import plix.fwi : watchpt_bench;
    watchpt_bench();
}

void tlb_miss() {
    pagetable.map(0, 0x8000_0000, PtLevel.mega, Perm.rwx);
    vm_fence();
    enum n = 1000;
    auto start = Timer.cycles();
    static foreach (i; 0 .. n) {
        asm {
            // comment for TLB hit
            "sfence.vma";
            "ld t0, 0(%0)" : : "r"(0) : "t0";
        }
    }
    auto end = Timer.cycles();
    printf("tlb_miss: %ld\n", (end - start) / n);
}

void tlb_miss_individual() {
    pagetable.map(0, 0x8000_0000, PtLevel.normal, Perm.rwx);
    vm_fence();
    enum n = 100;
    foreach (i; 0 .. n) {
        // comment for TLB hit
        vm_fence();
        // asm {
        //     "sfence.vma %0" : : "r"(0x8000_0000);
        // }
        auto start = Timer.cycles();
        asm {
            "ld t0, 0(%0)" : : "r"(0) : "t0";
        }
        auto end = Timer.cycles();
        printf("tlb_miss_individual: %ld\n", end - start);
    }
}

extern (C) extern void emptyvec();

void pagefault_individual() {
    Csr.stvec = cast(uintptr) &emptyvec;
    pagetable.map(0, 0x8000_0000, PtLevel.normal, Perm.r);
    vm_fence();

    enum n = 100;
    foreach (i; 0 .. n) {
        // comment for TLB hit
        // vm_fence();
        auto start = Timer.cycles();
        asm {
            "sd t0, 0(%0)" : : "r"(0) : "t0";
        }
        auto end = Timer.cycles();
        printf("pagefault: %ld\n", end - start);
    }
}
