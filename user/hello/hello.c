#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <assert.h>
#include <string.h>

#include "syslib.h"

#define BACKSPACE 127

int main() {
    printf("Hello Multiplix!\n");

    printf("Running file system test...\n");

    int fd = open("/README.md", 0, 0);
    printf("opened /README.md: %d\n", fd);
    struct mstat st;
    mstat(fd, &st);
    printf("type: %d, size: %d\n", st.type, st.size);

    char data[32];
    read(fd, data, 18);
    data[18] = 0;
    assert(strcmp(data, "# Multiplix kernel") == 0);

    printf("PASS\n");

    printf("Running fork test...\n");

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

    /* while (1) { */
    /*     char c; */
    /*     read(0, &c, 1); */
    /*     if (c == BACKSPACE) { */
    /*         printf("\b \b"); */
    /*     } else { */
    /*         printf("%c", c); */
    /*     } */
    /* } */
}
