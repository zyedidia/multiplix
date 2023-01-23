module ulib.rand;

// TODO: improve random number generator

ushort lfsr = 0xACE1u;
uint bit;

ushort gen_ushort() {
    bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5) ) & 1;
    lfsr = cast(ushort) ((lfsr >> 1) | (bit << 15));
    return lfsr;
}

uint gen_uint() {
    return (gen_ushort() << 16) | gen_ushort();
}

void seed(ushort seed) {
    lfsr = seed;
}
