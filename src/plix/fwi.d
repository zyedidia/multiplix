module plix.fwi;

import plix.monitor : monitor_func;
import plix.arch.monitor : monitor_call;

void wakeup_cores() {
    cast(void) monitor_call(monitor_func.wakeup_cores);
}
