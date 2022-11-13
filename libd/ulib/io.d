module ulib.io;

import ulib.string : itoa;
import ulib.math : min, max;
import ulib.trait : isInt, Unqual;

import sys = ulib.sys;

struct File {
public:
    void function(ubyte) putc;

    this(void function(ubyte) putc) {
        this.putc = putc;
    }

    void write(Args...)(Args args) {
        foreach (arg; args) {
            alias T = typeof(arg);
            writeElem(cast(Unqual!T) arg);
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
    char[256] buffer;
    size_t size;

    void writeElem(T)(T* val) {
        writeElem("0x");
        writeElem(cast(uintptr) val, 16);
    }

    void writeElem(char ch) {
        if (size >= buffer.length) {
            flush();
        }
        buffer[size++] = ch;
    }

    void writeElem(string s) {
        while (s.length > 0) {
            auto a = min(s.length, buffer.length - size);
            buffer[size .. size + a] = s;
            s = s[a .. $];
            size += a;

            if (size >= buffer.length) {
                flush();
            }
        }
    }

    void writeElem(bool b) {
        writeElem(b ? "true" : "false");
    }

    void writeElem(S = long)(S value, uint base = 10) if (isInt!S) {
        char[S.sizeof * 8] buf;
        writeElem(itoa(value, buf, base));
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
