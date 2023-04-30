module plix.monitor;

import core.volatile : vst;

extern (C) extern __gshared ulong wakeup;

void wakeup_cores() {
    vst(&wakeup, 1);
}
