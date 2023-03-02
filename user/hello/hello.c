#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

#include "syslib.h"

int main() {
    int child = fork();
    fork();
    if (child != 0) {
        wait(NULL);
    }

    int pid = getpid();
    for (int i = 0; i < 5; i++) {
        printf("%d: loop %d\n", pid, i);
        usleep(10 * 1000);
    }
    exit(0);
}
