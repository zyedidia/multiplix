module ulib.sys;

import io = ulib.io;
import uart = uart;

__gshared io.File stdout = io.File(function(ubyte c) { uart.tx(c); });

void exit(ubyte code) {
    /* sys.reboot(); */
}
