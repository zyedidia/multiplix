#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>

#include "syslib.h"

int main() {
    int pid = getpid();
    for (int i = 0; i < 5; i++) {
        printf("%d: loop %d\n", pid, i);
    }
}
