#include <stdint.h>

#include "syscall.h"

#define SYS_GETPID 0
#define SYS_PUTC 1

int getpid() {
    return syscall_0(SYS_GETPID);
}

void putc(char c) {
    syscall_1(SYS_PUTC, c);
}

void print(char* s) {
    for (char c = *s; c != '\0'; c = *++s) {
        putc(c);
    }
}

long fact(int n) {
    if (n == 0)
        return 1;
    else
        return(n * fact(n-1));
}

int main() {
    print("Hello world\n");
    while (1) {}
}
