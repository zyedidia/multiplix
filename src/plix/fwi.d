module plix.fwi;

import plix.monitor : monitor_func;
import plix.arch.fwi : monitor_call;

void wakeup_cores() {
    cast(void) monitor_call(monitor_func.wakeup_cores);
}

void set_timer(ulong stime) {
    cast(void) monitor_call(monitor_func.set_timer, stime);
}
