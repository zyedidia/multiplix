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
    unsigned long count;
    for (int i = 0; i < 10; i++) {
        /* asm volatile ("mrs %0, pmccntr_el0" : "=r"(count) : : "x0"); */
        /* syscall_0(count); */
        asm volatile ("csrr %0, cycle" : "=r"(count));
        syscall_0(count);
    }
    exit();
}
