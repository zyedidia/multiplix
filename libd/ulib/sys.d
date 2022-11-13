module ulib.sys;

import io = ulib.io;
import uart = uart;
import kernel = kernel;

__gshared io.File stdout = io.File(function(ubyte c) { uart.tx(c); });

void exit(ubyte code) {
    kernel.shutdown();
}
