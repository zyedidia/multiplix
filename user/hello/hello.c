#include <stdint.h>

#include "syscall.h"

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
    /* int child = fork(); */
    /* if (child != 0) { */
    /*     wait(); */
    /* } */
    /* int pid = getpid(); */
    for (int i = 0; i < 40; i++) {
        write(1, "hello\n", 6);
        nops(10000000);
    }
    exit();
}
