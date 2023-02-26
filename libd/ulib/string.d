module ulib.string;

import ulib.trait;

string itoa(S)(S input, char[] buf, uint base = 10) if (isInt!S) {
    size_t pos = buf.length;
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

bool equals(string a, string b) {
    if (a.length != b.length) {
        return false;
    }
    for (uint i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}

string tostr(const char* s) {
    import ulib.memory;
    return cast(string) s[0 .. strlen(s)];
}
