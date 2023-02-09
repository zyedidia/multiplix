module ulib.hash;

ulong hash_uint(uint key) {
    key = ((key >> 16) ^ key) * 0x119de1f3;
    key = ((key >> 16) ^ key) * 0x119de1f3;
    key = (key >> 16) ^ key;
    return key;
}
