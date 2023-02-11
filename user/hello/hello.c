#include <stdint.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdio.h>

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
    printf("Hello world\n");
    /* int child = fork(); */
    /* if (child != 0) { */
    /*     wait(NULL); */
    /* } */
    /* int pid = getpid(); */
    /* for (int i = 0; i < 40; i++) { */
    /*     printf("process: %d\n", pid); */
    /*     nops(10000000 / 2); */
    /* } */
    return 0;
}
