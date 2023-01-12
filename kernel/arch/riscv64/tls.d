module kernel.arch.riscv64.tls;

enum tcb_size = 0;

void set_tls_base(uintptr base) {
    asm {
        "mv tp, %0" : : "r"(base) : "memory";
    }
}
