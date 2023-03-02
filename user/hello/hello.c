#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

#include "syslib.h"

int main() {
    fork();
    int child = fork();
    int pid = getpid();
    if (child != 0) {
        printf("%d: waiting\n", pid);
        int x = wait(NULL);
        printf("%d: done waiting for %d\n", pid, x);
    }

    for (int i = 0; i < 5; i++) {
        printf("%d: loop %d\n", pid, i);
        usleep(100 * 1000);
    }
}
