// This module implements utilities for meta-programming.
module ulib.meta;

// returns true if the type 'val' is within the type tuple 'list'
enum contains(val, list...) = () {
    static foreach (idx, arg; list) {
        static if (is(val == arg)) {
            return true;
        }
    }
    return false;
}();

import ulib.trait;

template itoa(S) if (isInt!S) {
    alias itoa = function(S s, uint base = 10) {
        string str = "";
        auto num = s;
        bool sign = false;

        static if (S.min < 0) {
            if (num < 0) {
                sign = true;
                num = -num;
            }
        }

        do {
            auto rem = num % base;
            char c = cast(char)((rem > 9) ? (rem - 10) + 'a' : rem + '0');
            str = c ~ str;
            num /= base;
        }
        while (num);

        if (sign) {
            str = "-" ~ str;
        }

        return str;
    };
}
