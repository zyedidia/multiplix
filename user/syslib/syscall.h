#pragma once

#include <stddef.h>
#include <time.h>

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

enum {
    SYS_WRITE  = 0,
    SYS_GETPID = 1,
    SYS_EXIT   = 2,
    SYS_FORK   = 3,
    SYS_WAIT   = 4,
    SYS_SBRK   = 5,
    SYS_USLEEP = 6,
    SYS_READ   = 7,
};
