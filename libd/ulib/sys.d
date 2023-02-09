module ulib.sys;

import io = ulib.io;

import kernel.board;

__gshared io.File stdout = io.File(function(ubyte c) { Uart.tx(c); });
