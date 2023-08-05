module core.fmt;

import core.stdc.stdarg;
import core.trait : Unqual;

struct Formatter {
    void function(ubyte) putc;

    // Template the constructor so that we can run it at compile-time (the
    // source code must be exposed in the interface file).
    this()(void function(ubyte) putc) {
        this.putc = putc;
    }

    void write(Args...)(Args args) {
        foreach (arg; args) {
            write_elem(arg);
        }
    }

    void vwritef(scope const char* fmt, va_list ap) {
        assert(fmt, "null format");

        char c;

        for (int i = 0; (c = fmt[i]) != 0; i++) {
            if (c != '%') {
                putc(c);
                continue;
            }
            c = fmt[++i];
            if (c == 0)
                break;
            switch (c) {
                case 'l':
                    c = fmt[++i];
                    if (c == 0)
                        break;
                    switch (c) {
                        case 'd':
                            write_elem(va_arg!(long)(ap), 10);
                            break;
                        case 'u':
                            write_elem(va_arg!(ulong)(ap), 10);
                            break;
                        case 'x':
                            write_elem("0x");
                            write_elem(va_arg!(ulong)(ap), 16);
                            break;
                        default:
                            write_elem("%l");
                            putc(c);
                            break;
                    }
                    break;
                case 'd':
                    write_elem(va_arg!(int)(ap), 10);
                    break;
                case 'u':
                    write_elem(va_arg!(uint)(ap), 10);
                    break;
                case 'x':
                    write_elem("0x");
                    write_elem(va_arg!(uint)(ap), 16);
                    break;
                case 'p':
                    write_elem("0x");
                    write_elem(va_arg!(ulong)(ap), 16);
                    break;
                case 'c':
                    write_elem(va_arg!(char)(ap));
                    break;
                case 's':
                    immutable(char)* s = va_arg!(immutable(char)*)(ap);
                    if (!s)
                        s = "(null)".ptr;
                    for (; *s; s++)
                        putc(*s);
                    break;
                case '%':
                    putc('%');
                    break;
                default:
                    putc('%');
                    putc(c);
                    break;
            }
        }
    }

    void write_elem(T)(T* val) {
        write_elem("0x");
        write_elem(cast(uintptr) val, 16);
    }

    void write_elem(char ch) {
        putc(ch);
    }

    void write_elem(string s) {
        foreach (c; s) {
            write_elem(c);
        }
    }

    void write_elem(bool b) {
        write_elem(b ? "true" : "false");
    }

    void write_elem(S = long)(S value, uint base = 10) {
        char[S.sizeof * 8] buf = void;
        write_elem(itoa(value, buf, base));
    }
}

string itoa(S)(S input, char[] buf, uint base = 10) {
    usize pos = buf.length;
    bool sign = false;
    Unqual!S num = input;

    static if (S.min < 0) {
        if (num < 0) {
            sign = true;
            num = -num;
        }
    }

    do {
        const auto rem = num % base;
        buf[--pos] = cast(char)((rem > 9) ? (rem - 10) + 'a' : rem + '0');
        num /= base;
    }
    while (num);

    if (sign) {
        buf[--pos] = '-';
    }

    return cast(string) buf[pos .. $];
}
