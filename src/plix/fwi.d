module plix.fwi;

import plix.monitor : monitor_func;
import plix.arch.fwi : monitor_call;

void wakeup_cores() {
    cast(void) monitor_call(monitor_func.wakeup_cores);
}

void set_timer(ulong stime) {
    cast(void) monitor_call(monitor_func.set_timer, stime);
}

void install_empty_handler() {
    cast(void) monitor_call(monitor_func.install_empty_handler);
}

void install_time_handler() {
    cast(void) monitor_call(monitor_func.install_time_handler);
}

void install_watchpt_handler() {
    cast(void) monitor_call(monitor_func.install_watchpt_handler);
}

void watchpt_bench() {
    cast(void) monitor_call(monitor_func.watchpt_bench);
}
