#include <stdint.h>

#include "syscall.h"

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

void nops(unsigned long n) {
    for (unsigned long i = 0; i < n; i++) {
        asm volatile ("nop");
    }
}

int main() {
    int pid = getpid();
    for (int i = 0; i < 30; i++) {
        print("process: ");
        putc('0' + pid);
        putc('\n');
        nops(10000000 / 2);
    }
    exit();
}
