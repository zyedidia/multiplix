module builtins;

extern (C):

void* memcpy(void* dst, const(void)* src, usize n) {
    char* s = cast(char*) src;
    for (char* d = cast(char*) dst; n > 0; --n, ++s, ++d) {
        *d = *s;
    }
    return dst;
}

void* memmove(void* dst, const(void)* src, usize n) {
    char* s = cast(char*) src;
    char* d = cast(char*) dst;
    if (s < d && s + n > d) {
        s += n, d += n;
        while (n-- > 0) {
            *--d = *--s;
        }
    } else {
        while (n-- > 0) {
            *d++ = *s++;
        }
    }
    return dst;
}

void* memset(void* v, int c, usize n) {
    for (char* p = cast(char*) v; n > 0; ++p, --n) {
        *p = cast(char) c;
    }
    return v;
}

int memcmp(const(void)* _s1, const(void)* _s2, usize nbytes) {
    const(ubyte)* s1 = cast(const(ubyte)*) _s1;
    const(ubyte)* s2 = cast(const(ubyte)*) _s2;

    for (int i = 0; i < nbytes; i++) {
        const int v = s1[i] - s2[i];
        if (v)
            return v;
    }
    return 0;
}

usize strlen(const(char)* s) {
    usize n;
    for (n = 0; *s != '\0'; ++s) {
        ++n;
    }
    return n;
}
