module plix.monitor;

import core.volatile : vst;

import plix.print : printf;
import plix.arch.cpu : sev;
import plix.arch.cache : clean_dcache, sync_fence, insn_fence;
import plix.arch.monitor.boot : enable_vm;

extern (C) extern __gshared ulong wakeup;

enum monitor_func {
    wakeup_cores = 0,
}

usize fwi_handler(usize num) {
    switch (num) {
    case monitor_func.wakeup_cores:
        wakeup_cores();
        break;
    default:
        printf("invalid monitor call: %ld\n", num);
        return usize.max;
    }
    return 0;
}

void wakeup_cores() {
    import config : ismonitor;
    assert(ismonitor());
    vst(&wakeup, ulong.max);
    sev();

    enable_vm();
}
