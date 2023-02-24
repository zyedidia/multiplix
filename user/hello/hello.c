#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>

#include "syslib.h"

int main() {
    for (int i = 0; i < 5; i++) {
        getpid();
        for (int j = 0; j < 50000000; j++) {
            asm volatile ("nop");
        }
    }
    exit(0);
}
