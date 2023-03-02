module ulib.print;

import kernel.spinlock;
private shared Spinlock lock;

void print(Args...)(Args args) {
    lock.lock();
    import sys = ulib.sys;
    sys.stdout.write(args);
    lock.unlock();
}
void println(Args...)(Args args) {
    lock.lock();
    import sys = ulib.sys;
    sys.stdout.write(args, '\n');
    lock.unlock();
}
import core.stdc.stdarg;
pragma(printf)
extern (C) void printf(scope const char* fmt, ...) {
    lock.lock();
    import sys = ulib.sys;
    va_list ap;
    va_start(ap, fmt);
    sys.stdout.vwritef(fmt, ap);
    va_end(ap);
    lock.unlock();
}

extern (C) void vprintf(scope const char* fmt, va_list ap) {
    lock.lock();
    import sys = ulib.sys;
    sys.stdout.vwritef(fmt, ap);
    lock.unlock();
}
