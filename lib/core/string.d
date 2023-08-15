module core.string;

int strncmp(const(char)* a, const(char)* b, usize n) {
    while (true) {
        ubyte ac = n ? *a : '\0', bc = n ? *b : '\0';
        if (ac == '\0' || bc == '\0' || ac != bc) {
            return (ac > bc) - (ac < bc);
        }
        ++a, ++b, --n;
    }
}
