module ulib.math;

T min(T, U)(T a, U b) if (is(T == U) && is(typeof(a < b))) {
    return b < a ? b : a;
}

T max(T, U)(T a, U b) if (is(T == U) && is(typeof(a < b))) {
    return a < b ? b : a;
}
