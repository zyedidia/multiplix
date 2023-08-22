#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/wait.h>
#include <fcntl.h>

#include "syslib.h"

#define BACKSPACE 127

int main() {
    int fd = open("/README.md", 0, 0);
    printf("open: %d\n", fd);
    struct mstat st;
    mstat(fd, &st);
    printf("type: %d, size: %d\n", st.type, st.size);

    char data[32];
    read(fd, data, 31);
    data[31] = 0;
    printf("%s\n", data);

    while (1) {
        char c;
        read(0, &c, 1);
        if (c == BACKSPACE) {
            printf("\b \b");
        } else {
            printf("%c", c);
        }
    }

    /* fork(); */
    /* int child = fork(); */
    /* int pid = getpid(); */
    /* if (child != 0) { */
    /*     printf("%d: waiting\n", pid); */
    /*     int x = wait(NULL); */
    /*     printf("%d: done waiting for %d\n", pid, x); */
    /* } */
    /*  */
    /* for (int i = 0; i < 5; i++) { */
    /*     printf("%d: loop %d\n", pid, i); */
    /*     usleep(100 * 1000); */
    /* } */
}
