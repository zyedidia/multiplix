#include <stdint.h>

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

#define SYS_GETPID 0
#define SYS_PUTC 1
#define SYS_SINGLESTEP_ON 2
#define SYS_SINGLESTEP_OFF 3

int getpid() {
    return syscall_0(SYS_GETPID);
}

void putc(char c) {
    syscall_1(SYS_PUTC, c);
}

void singlestep_on() {
    syscall_0(SYS_SINGLESTEP_ON);
}

void singlestep_off() {
    syscall_0(SYS_SINGLESTEP_OFF);
}

void print(char* s) {
    for (char c = *s; c != '\0'; c = *++s) {
        putc(c);
    }
}

long fact(int n) {
    if (n == 0)
        return 1;
    else
        return(n * fact(n-1));
}

int main() {
    /* singlestep_on(); */
    print("Hello world\n");
    /* singlestep_off(); */
    while (1) {}
}

/* int main() { */
/*     getpid(); */
/*     while (1) {} */
/* } */
