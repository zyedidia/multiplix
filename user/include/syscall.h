#pragma once

#ifdef RISCV64
static inline uintptr_t syscall_0(int symno) {
    register uintptr_t a7 asm("a7") = symno;
    register uintptr_t a0 asm("a0");
    asm volatile("ecall" : "=r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_1(int symno, uintptr_t arg0) {
    register uintptr_t a7 asm("a7") = symno;
    register uintptr_t a0 asm("a0") = arg0;
    asm volatile("ecall" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_2(int symno, uintptr_t arg0, uintptr_t arg1) {
    register uintptr_t a7 asm("a7") = symno;
    register uintptr_t a0 asm("a0") = arg0;
    register uintptr_t a1 asm("a1") = arg1;
    asm volatile("ecall" : "+r"(a0) : "r"(a7), "r"(a1) : "memory");
    return a0;
}
#else
static inline uintptr_t syscall_0(int symno) {
    register uintptr_t a7 asm("x7") = symno;
    register uintptr_t a0 asm("x0");
    asm volatile("svc #0" : "=r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_1(int symno, uintptr_t arg0) {
    register uintptr_t a7 asm("x7") = symno;
    register uintptr_t a0 asm("x0") = arg0;
    asm volatile("svc #0" : "+r"(a0) : "r"(a7) : "memory");
    return a0;
}
static inline uintptr_t syscall_2(int symno, uintptr_t arg0, uintptr_t arg1) {
    register uintptr_t a7 asm("x7") = symno;
    register uintptr_t a0 asm("x0") = arg0;
    register uintptr_t a1 asm("x1") = arg1;
    asm volatile("svc #0" : "+r"(a0) : "r"(a7), "r"(a1) : "memory");
    return a0;
}
#endif

#define SYS_PUTC 0
#define SYS_GETPID 1
#define SYS_EXIT 2
#define SYS_FORK 3

static inline int getpid() {
    return syscall_0(SYS_GETPID);
}

static inline void putc(char c) {
    syscall_1(SYS_PUTC, c);
}

static inline void exit() {
    syscall_0(SYS_EXIT);
}

static inline int fork() {
    return syscall_0(SYS_FORK);
}
