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

extern (C) void kmain(uint coreid, bool primary) {
    for (int i = 0; i < 10; i++) {
        bench_watchpoint();
    }

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

import plix.arch.aarch64.sysreg : SysReg, DbgLsc, Dbgbcr;

void set_watchpoint1(uintptr addr, uint lsc) {
    SysReg.dbgwvr0_el1 = addr;
    SysReg.dbgwcr0_el1 = lsc << 3 | 0b11111111 << 5 | Dbgbcr.el1_el0 | Dbgbcr.e;
}
void set_watchpoint2(uintptr addr, uint lsc) {
    SysReg.dbgwvr1_el1 = addr;
    SysReg.dbgwcr1_el1 = lsc << 3 | 0b11111111 << 5 | Dbgbcr.el1_el0 | Dbgbcr.e;
}
void set_watchpoint3(uintptr addr, uint lsc) {
    SysReg.dbgwvr2_el1 = addr;
    SysReg.dbgwcr2_el1 = lsc << 3 | 0b11111111 << 5 | Dbgbcr.el1_el0 | Dbgbcr.e;
}
void set_watchpoint4(uintptr addr, uint lsc) {
    SysReg.dbgwvr3_el1 = addr;
    SysReg.dbgwcr3_el1 = lsc << 3 | 0b11111111 << 5 | Dbgbcr.el1_el0 | Dbgbcr.e;
}

void bench_hvc() {
    auto x = SysReg.ttbr0_el1;
    auto start = Timer.cycles();
    enum n = 100;
    import gcc.attributes;
    @register("x7") ulong c;
    static foreach (i; 0 .. n) {
        c = 5;
        asm {
            "hvc 0" : : "r"(c);
        }
    }
    auto end = Timer.cycles();
    printf("time: %ld\n", (end - start) / n);
}

void bench_watchpoint() {
    auto x = SysReg.ttbr0_el1;
    auto start = Timer.cycles();
    enum n = 100;
    static foreach (i; 0 .. n) {
        asm {
            "dsb sy";
        }
        // set_watchpoint1(0x1000, DbgLsc.rdwr);
        // set_watchpoint2(0x1000, DbgLsc.rdwr);
        // set_watchpoint3(0x1000, DbgLsc.rdwr);
        // set_watchpoint4(0x1000, DbgLsc.rdwr);
        SysReg.ttbr0_el1 = 0;
        asm {
            "isb";
        }
    }
    auto end = Timer.cycles();
    printf("time: %ld\n", (end - start) / n);
}
