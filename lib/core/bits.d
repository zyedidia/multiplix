module core.bits;

import core.trait;

pragma(inline, true)
T mask(T)(uint nbits) if (isint!T) {
    if (nbits == T.sizeof * 8) {
        return cast(T) ~(cast(T) 0);
    }
    return cast(T) (((cast(T) 1) << nbits) - 1);
}

pragma(inline, true)
T get(T)(T x, uint ub, uint lb) if (isint!T) {
    return cast(T) ((x >> lb) & mask!T(ub - lb + 1));
}

pragma(inline, true)
T get(T)(T x, uint bit) if (isint!T) {
    return cast(T) ((x >> bit) & (cast(T) 1));
}

pragma(inline, true)
T clear(T)(T x, uint hi, uint lo) if (isint!T) {
    T m = mask!T(hi - lo + 1);
    return cast(T) (x & ~(m << lo));
}

pragma(inline, true)
T clear(T)(T x, uint bit) if (isint!T) {
    return cast(T) (x & ~((cast(T) 1) << bit));
}

pragma(inline, true)
T set(T)(T x, uint bit) if (isint!T) {
    return cast(T) (x | ((cast(T) 1) << bit));
}

pragma(inline, true)
T write(T)(T x, uint bit, uint val) if (isint!T) {
    x = clear(x, bit);
    return cast(T) (x | (val << bit));
}

pragma(inline, true)
T write(T)(T x, uint hi, uint lo, T val) if (isint!T) {
    return cast(T) (clear(x, hi, lo) | (val << lo));
}

pragma(inline, true)
T remap(T)(T i, uint from, uint to) if (isint!T) {
    return cast(T) (get(i, from) << to);
}

pragma(inline, true)
T remap(T)(T i, uint from_ub, uint from_lb, uint to_ub, uint to_lb) {
    return cast(T) (get(i, from_ub, from_lb) << to_lb);
}

pragma(inline, true)
T sext(T, UT)(UT x, uint width) {
    ulong n = (T.sizeof * 8 - 1) - (width-1);
    return (cast(T)(x << n)) >> n;
}

version (GNU) {
    import gcc.builtins;

    usize msb(uint x) {
        return x ? x.sizeof * 8 - __builtin_clz(x) : 0;
    }

    usize msb(ulong x) {
        return x ? x.sizeof * 8 - __builtin_clzll(x) : 0;
    }

    T bswap(T)(T val) {
        static if (is(T == ushort) || is(T == short)) {
            return cast(T) __builtin_bswap16(cast(ushort) val);
        } else static if (is(T == uint) || is(T == int)) {
            return cast(T) __builtin_bswap32(cast(uint) val);
        } else static if (is(T == ulong) || is(T == long)) {
            return cast(T) __builtin_bswap64(cast(ulong) val);
        } else {
            static assert(0, "invalid bswap type");
        }
    }
}

version (LDC) {
    import ldc.intrinsics;

    usize msb(uint x) {
        return cast(usize)(x ? x.sizeof * 8 - llvm_ctlz!uint(x, true) : 0);
    }

    usize msb(ulong x) {
        return cast(usize)(x ? x.sizeof * 8 - llvm_ctlz!ulong(x, true) : 0);
    }

    usize lsb(ulong x) {
        return cast(usize)(x == 0 ? 0 : llvm_ctlz!ulong(x, true));
    }

    T bswap(T)(T val) {
        return llvm_bswap!T(val);
    }
}

/**
 * The following bitfield code is adapted from PowerNex.
 *
 * Copyright: © 2015-2017, Dan Printzell
 * License: $(LINK2 https://www.mozilla.org/en-US/MPL/2.0/, Mozilla Public License Version 2.0)
 *  (See accompanying file PowerNex/LICENSE)
 * Authors: $(LINK2 https://vild.io/, Dan Printzell)
 */

template field(alias data, args...) {
    enum field = bitfieldShim!((typeof(data)).stringof, data, args).ret;
}

template bitfieldShim(const char[] typeStr, alias data, args...) {
    enum name = data.stringof;
    enum ret = bitfieldImpl!(typeStr, name, 0, args).ret;
}

template bitfieldImpl(const char[] typeStr, const char[] nameStr, int offset, args...) {
    static if (!args.length)
        enum ret = "";
    else static if (args.length == 1 && !args[0].length)
        enum ret = bitfieldImpl!(typeStr, nameStr, offset + args[1], args[2 .. $]).ret;
    else {
        enum name = args[0];
        enum size = args[1];
        enum mask = bitmask!size;
        static if (args.length > 2 && is(args[2])) {
            enum type = args[2].stringof;
            enum nextItemAt = 3;
        } else {
            enum type = targetType!size;
            enum nextItemAt = 2;
        }

        enum getter = "///\n" ~ type ~ " " ~ name ~ "() const { return cast(" ~ type
            ~ ")((" ~ nameStr ~ " >> " ~ itoh!(offset) ~ ") & " ~ itoh!(mask) ~ "); } \n";

        enum setter = "///\nvoid " ~ name ~ "(" ~ type ~ " val) { " ~ nameStr
            ~ " = (" ~ nameStr ~ " & " ~ itoh!(~(mask << offset)) ~ ") | ((val & " ~ itoh!(
                    mask) ~ ") << " ~ itoh!(offset) ~ "); } \n";

        enum ret = getter ~ setter ~ bitfieldImpl!(typeStr, nameStr,
                    offset + size, args[nextItemAt .. $]).ret;
    }
}

template bitmask(long size) {
    const long bitmask = (1UL << size) - 1;
}

template targetType(long size) {
    static if (size == 1)
        enum targetType = "ubyte";
    else static if (size <= 8)
        enum targetType = "ubyte";
    else static if (size <= 16)
        enum targetType = "ushort";
    else static if (size <= 32)
        enum targetType = "uint";
    else static if (size <= 64)
        enum targetType = "ulong";
    else
        static assert(0);
}

template itoh(long i) {
    enum itoh = "0x" ~ intToStr!(i, 16) ~ "UL";
}

template digits(long i) {
    enum digits = "0123456789abcdefghijklmnopqrstuvwxyz"[0 .. i];
}

template intToStr(ulong i, int base) {
    static if (i >= base)
        enum intToStr = intToStr!(i / base, base) ~ digits!base[i % base];
    else
        enum intToStr = "" ~ digits!base[i % base];
}

