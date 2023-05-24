module plix.monitor;

import core.volatile : vst;

import plix.print : printf;
import plix.arch.cpu : sev;
import plix.arch.cache : clean_dcache, sync_fence, insn_fence;
import plix.arch.monitor.boot : enable_vm;
import plix.arch.timer : monitor_set_timer;

extern (C) extern __gshared ulong wakeup;

enum monitor_func {
    wakeup_cores = 0,
    set_timer = 1,
    install_empty_handler = 2,
    install_time_handler = 3,
    install_watchpt_handler = 4,
    watchpt_bench = 5,
}

usize fwi_handler(usize num, usize arg0) {
    switch (num) {
    case monitor_func.wakeup_cores:
        monitor_wakeup_cores();
        break;
    case monitor_func.set_timer:
        monitor_set_timer(arg0);
        break;
    case monitor_func.install_empty_handler:
        install_empty_handler();
        break;
    case monitor_func.install_time_handler:
        install_time_handler();
        break;
    case monitor_func.install_watchpt_handler:
        install_watchpt_handler();
        break;
    case monitor_func.watchpt_bench:
        watchpt_bench();
        break;
    default:
        printf("invalid monitor call: %ld\n", num);
        return usize.max;
    }
    return 0;
}

void monitor_wakeup_cores() {
    import config : ismonitor;
    assert(ismonitor());
    vst(&wakeup, ulong.max);
    clean_dcache(&wakeup, ulong.sizeof);
    sync_fence();
    insn_fence();
    sev();

    // TODO: enable VM
    // enable_vm();
}

import plix.arch.riscv64.csr : Csr;

extern (C) extern void emptyvec();
extern (C) extern void timevec();
extern (C) extern void watchptvec();

void install_empty_handler() {
    Csr.mtvec = cast(uintptr) &emptyvec;
}

void install_time_handler() {
    Csr.mtvec = cast(uintptr) &timevec;
}

void install_watchpt_handler() {
    Csr.mtvec = cast(uintptr) &watchptvec;
}

void watchpt_bench() {
    printf("watchpt bench\n");
}
