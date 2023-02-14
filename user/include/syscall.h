#pragma once

#include <stddef.h>

#ifdef RISCV64
static inline uintptr_t syscall_0(int sysno) {
    register uintptr_t a7 asm("a7") = sysno;
    register uintptr_t a0 asm("a0");
    asm volatile("ecall" : "=r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_1(int sysno, uintptr_t arg0) {
    register uintptr_t a7 asm("a7") = sysno;
    register uintptr_t a0 asm("a0") = arg0;
    asm volatile("ecall" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_2(int sysno, uintptr_t arg0, uintptr_t arg1) {
    register uintptr_t a7 asm("a7") = sysno;
    register uintptr_t a0 asm("a0") = arg0;
    register uintptr_t a1 asm("a1") = arg1;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1) : "memory");
    return a0;
}
static inline uintptr_t syscall_3(int sysno, uintptr_t arg0, uintptr_t arg1, uintptr_t arg2) {
    register uintptr_t a7 asm("a7") = sysno;
    register uintptr_t a0 asm("a0") = arg0;
    register uintptr_t a1 asm("a1") = arg1;
    register uintptr_t a2 asm("a2") = arg2;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2) : "memory");
    return a0;
}
#else
static inline uintptr_t syscall_0(int sysno) {
    register uintptr_t a7 asm("x7") = sysno;
    register uintptr_t a0 asm("x0");
    asm volatile("svc #0" : "=r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_1(int sysno, uintptr_t arg0) {
    register uintptr_t a7 asm("x7") = sysno;
    register uintptr_t a0 asm("x0") = arg0;
    asm volatile("svc #0" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_2(int sysno, uintptr_t arg0, uintptr_t arg1) {
    register uintptr_t a7 asm("x7") = sysno;
    register uintptr_t a0 asm("x0") = arg0;
    register uintptr_t a1 asm("x1") = arg1;
    asm volatile("svc #0" : "+r"(a0) : "r"(a7), "r"(a1) : "memory");
    return a0;
}
static inline uintptr_t syscall_3(int sysno, uintptr_t arg0, uintptr_t arg1, uintptr_t arg2) {
    register uintptr_t a7 asm("x7") = sysno;
    register uintptr_t a0 asm("x0") = arg0;
    register uintptr_t a1 asm("x1") = arg1;
    register uintptr_t a2 asm("x2") = arg2;
    asm volatile("svc #0" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2) : "memory");
    return a0;
}
#endif

#define SYS_WRITE     0
#define SYS_GETPID    1
#define SYS_EXIT      2
#define SYS_FORK      3
#define SYS_WAIT      4
#define SYS_NANOSLEEP 6

static inline int getpid() {
    return syscall_0(SYS_GETPID);
}

static inline void write(int fd, char* buffer, size_t sz) {
    syscall_3(SYS_WRITE, fd, (uintptr_t) buffer, sz);
}

static inline void exit() {
    syscall_0(SYS_EXIT);
}

static inline int fork() {
    return syscall_0(SYS_FORK);
}

static inline int wait() {
    return syscall_0(SYS_WAIT);
}

typedef long time_t;
struct timespec {
    time_t tv_sec;
    long tv_nsec;
};

static inline int nanosleep(const struct timespec *req) {
    unsigned long ns = req->tv_sec * 1000000000 + req->tv_nsec;
    return syscall_1(SYS_NANOSLEEP, ns);
}
