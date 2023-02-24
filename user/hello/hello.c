#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>

#include "syslib.h"

int main() {
    int child = fork();
    if (child != 0) {
        wait();
    }

    for (int i = 0; i < 5; i++) {
        getpid();
        usleep(100 * 1000);
    }
    exit(0);
}
