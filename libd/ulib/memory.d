module ulib.memory;

extern (C):

void* memcpy(void* dst, const(void)* src, size_t n);

void* memmove(void* dst, void* src, size_t n);

void* memset(void* v, int c, size_t n);

int memcmp(const(void)* _s1, const(void)* _s2, size_t nbytes);

size_t strlen(const(char)* s) nothrow;
