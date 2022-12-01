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

int getpid() {
    return syscall_0(0);
}

int main() {
    while (1) {
        getpid();
    }
}
