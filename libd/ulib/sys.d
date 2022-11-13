module ulib.sys;

import io = ulib.io;
import kernel = kernel;

extern (C) {
    void ulib_tx(ubyte b);
    void ulib_exit(ubyte code);
}

__gshared io.File stdout = io.File(function(ubyte c) { ulib_tx(c); });

void exit(ubyte code) {
    ulib_exit(code);
}
