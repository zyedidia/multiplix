module ulib.print;

import kernel.spinlock;

import sys = ulib.sys;

void print(Args...)(Args args) {
    sys.stdout.write(args);
}
void println(Args...)(Args args) {
    sys.stdout.write(args, '\n');
}
import core.stdc.stdarg;
pragma(printf)
extern (C) void printf(scope const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    sys.stdout.vwritef(fmt, ap);
    va_end(ap);
}

extern (C) void vprintf(scope const char* fmt, va_list ap) {
    sys.stdout.vwritef(fmt, ap);
}
