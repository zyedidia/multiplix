module ulib.string;

import ulib.trait;

string itoa(S)(S num, char[] buf, uint base = 10) if (isInt!S) {
    size_t pos = buf.length;
    bool sign = false;

    static if (S.min < 0) {
        if (num < 0) {
            sign = true;
            num = -num;
        }
    }

    do {
        auto rem = num % base;
        buf[--pos] = cast(char)((rem > 9) ? (rem - 10) + 'a' : rem + '0');
        num /= base;
    }
    while (num);

    if (sign) {
        buf[--pos] = '-';
    }

    return cast(string) buf[pos .. $];
}
