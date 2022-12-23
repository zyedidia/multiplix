module ulib.io;

import ulib.string : itoa;
import ulib.math : min, max;
import ulib.trait : isInt;

import sys = ulib.sys;

struct File {
public:
    void function(ubyte) putc = void;

    this(void function(ubyte) putc) {
        this.putc = putc;
    }

    void write(Args...)(Args args) {
        foreach (arg; args) {
            write_elem(arg);
        }
    }

    void flush() {
        if (size > 0) {
            for (size_t i = 0; i < size; i++) {
                putc(buffer[i]);
            }
            size = 0;
        }
    }

private:
    char[256] buffer = void;
    size_t size = 0;

    void write_elem(T)(T* val) {
        write_elem("0x");
        write_elem(cast(uintptr) val, 16);
    }

    void write_elem(char ch) {
        if (size >= buffer.length) {
            flush();
        }
        buffer[size++] = ch;
    }

    void write_elem(string s) {
        while (s.length > 0) {
            auto a = min(s.length, buffer.length - size);
            buffer[size .. size + a] = s[0 .. a];
            s = s[a .. $];
            size += a;

            if (size >= buffer.length) {
                flush();
            }
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

void write(Args...)(Args args) {
    sys.stdout.write(args);
    sys.stdout.flush();
}

void writeln(Args...)(Args args) {
    sys.stdout.write(args, '\n');
    sys.stdout.flush();
}
