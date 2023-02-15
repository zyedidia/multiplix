#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>

#include "syslib.h"

struct timespec delay = {.tv_sec = 1, .tv_nsec = 0};

int main() {
    /* int child = fork(); */
    /* if (child != 0) { */
    /*     wait(); */
    /* } */
    int pid = getpid();
    for (int i = 0; i < 5; i++) {
        printf("%d: hello %d\n", pid, i);
        nanosleep(&delay, NULL);
    }
    exit(0);
}
