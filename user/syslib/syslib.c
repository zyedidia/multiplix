#include <stddef.h>
#include <stdint.h>
#include <sys/stat.h>
#include <sys/times.h>

#include "syscall.h"

char *__env[1] = { 0 };
char **_environ = __env;

extern void exit(int code);
extern int main ();

void _start() {
    int ex = main();
    exit(ex);
}

int _execve(char *name, char **argv, char **env) {
    return -1;
}

void* _sbrk(int incr) {
    return (void*) syscall_1(SYS_SBRK, incr);
}

int _close(int file) {
    return -1;
}

int _fstat(int file, struct stat* st) {
    st->st_mode = S_IFCHR;
    return 0;
}

int _isatty(int file) {
    return 1;
}

int _lseek(int file, int ptr, int dir) {
    return 0;
}

void _exit(int status) {
    syscall_0(SYS_EXIT);
    while (1) {}
}

void _kill(int pid, int sig) {
    return;
}

int _getpid(void) {
    return syscall_0(SYS_GETPID);
}

int _write(int file, char* ptr, int len) {
    return syscall_3(SYS_WRITE, file, (uintptr_t) ptr, len);
}

int _read(int file, char* ptr, int len) {
    return syscall_3(SYS_READ, file, (uintptr_t) ptr, len);
}

int _fork(void) {
    return syscall_0(SYS_FORK);
}

int _wait() {
    return syscall_0(SYS_WAIT);
}

int _unlink(char* name) {
    return -1;
}

int _times(struct tms* buf) {
    return -1;
}

int usleep(uint64_t us) {
    return syscall_1(SYS_USLEEP, us);
}
