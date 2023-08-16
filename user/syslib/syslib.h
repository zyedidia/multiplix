#pragma once

#include <stdint.h>
#include <stddef.h>

struct mstat {
    int dev;
    unsigned ino;
    short type;
    short nlink;
    size_t size;
};

int usleep(uint64_t us);
int mstat(int file, struct mstat* st);
