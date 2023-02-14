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

struct timespec delay = {.tv_sec = 1, .tv_nsec = 0};

int main() {
    /* int child = fork(); */
    /* if (child != 0) { */
    /*     wait(); */
    /* } */
    /* int pid = getpid(); */
    for (int i = 0; i < 40; i++) {
        write(1, "hello\n", 6);
        nanosleep(&delay);
    }
    exit();
}
