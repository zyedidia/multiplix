module plix.monitor;

import core.volatile : vst;

import plix.print : printf;

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
    vst(&wakeup, 1);
}
