module plix.print;

import core.stdc.stdarg;
import core.fmt : Formatter;

import plix.spinlock : SpinGuard;

void uart_putc(ubyte b) {
    import plix.board : uart;
    uart.tx(b);
}

private shared SpinGuard!(Formatter) printer = SpinGuard!(Formatter)(Formatter(&uart_putc));

void print(Args...)(Args args) {
    auto p = printer.lock();
    p.write(args);
}

void println(Args...)(Args args) {
    print(args, '\n');
}

pragma(printf)
extern (C) void printf(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

extern (C) void vprintf(const char* fmt, va_list ap) {
    auto p = printer.lock();
    p.vwritef(fmt, ap);
}
