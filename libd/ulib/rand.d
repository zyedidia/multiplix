module ulib.rand;

// TODO: improve random number generator

// these variables are shared with no protection -- a little bit of additional
// non-determinism in the random number generator can't hurt right? (fix this
// at some point)
__gshared ushort lfsr = 0xACE1u;
__gshared uint bit;

ushort rand_ushort() {
    bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5) ) & 1;
    lfsr = cast(ushort) ((lfsr >> 1) | (bit << 15));
    return lfsr;
}

uint rand() {
    return (rand_ushort() << 16) | rand_ushort();
}

void seed(ushort seed) {
    lfsr = seed;
}
