module ulib.math;

T min(T, U)(T a, U b) if (is(T == U) && is(typeof(a < b))) {
    return b < a ? b : a;
}

T max(T, U)(T a, U b) if (is(T == U) && is(typeof(a < b))) {
    return a < b ? b : a;
}

ulong log2ceil(ulong x) {
    ulong n = 0;
    while (x >>= 1) ++n;
    return n;
}

ulong pow2ceil(ulong x) {
    ulong power = 1;
    while (power < x)
        power *= 2;
    return power;
}
