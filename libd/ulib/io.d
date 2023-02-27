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

    void writef(scope string format, ...) {
        va_list ap;

        assert(format, "null format");

        int c;

        va_start(ap, fmt);
        for (int i = 0; (c = fmt[i] & 0xff) != 0; i++) {
            if (c != '%') {
                putc(c);
                continue;
            }
            c = fmt[++i] & 0xff;
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
                case 'p':
                    write_elem(va_arg!(void*)(ap));
                case 's':
                    write_elem(va_arg!(string)(ap));
                case '%':
                    putc('%');
                    break;
                default:
                    putc('%');
                    putc(c);
                    break;
            }
        }
        va_end(ap);
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
