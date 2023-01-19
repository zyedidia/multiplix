module ulib.io;

import ulib.string : itoa;
import ulib.math : min, max;
import ulib.trait : isInt;

import sys = ulib.sys;

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

private:
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

    void write_elem(S = long)(S value, uint base = 10) if (isInt!S) {
        char[S.sizeof * 8] buf = void;
        write_elem(itoa(value, buf, base));
    }
}

void write(Args...)(Args args) {
    sys.stdout.write(args);
}

void writeln(Args...)(Args args) {
    sys.stdout.write(args, '\n');
}
