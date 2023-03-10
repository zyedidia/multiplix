module ulib.io;

import ulib.string : itoa;
import ulib.math : min, max;
import ulib.trait : isInt;

struct File {
public:
    @disable this();

    void function(ubyte) putc = void;

    this(void function(ubyte) putc) {
        this.putc = putc;
    }

    void write(Args...)(Args args) {
        foreach (arg; args) {
            write_elem(arg);
        }
    }

    import core.stdc.stdarg;
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

private:
    void write_elem(T)(T* val) {
        write_elem("0x");
        write_elem(cast(uintptr) val, 16);
    }

    void write_elem(Hex val) {
        write_elem(cast(void*) val.p);
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

    void write_elem(S = long)(S value, uint base = 10) if (isInt!S) {
        char[S.sizeof * 8] buf = void;
        write_elem(itoa(value, buf, base));
    }
}
