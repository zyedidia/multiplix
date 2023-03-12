module ulib.print;

import kernel.spinlock;

void print(Args...)(Args args) {
    import sys = ulib.sys;
    sys.stdout.write(args);
}
void println(Args...)(Args args) {
    import sys = ulib.sys;
    sys.stdout.write(args, '\n');
}
import core.stdc.stdarg;
pragma(printf)
extern (C) void printf(scope const char* fmt, ...) {
    import sys = ulib.sys;
    va_list ap;
    va_start(ap, fmt);
    sys.stdout.vwritef(fmt, ap);
    va_end(ap);
}

extern (C) void vprintf(scope const char* fmt, va_list ap) {
    import sys = ulib.sys;
    sys.stdout.vwritef(fmt, ap);
}
