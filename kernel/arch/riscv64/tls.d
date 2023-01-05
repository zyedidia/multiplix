module kernel.arch.riscv64.tls;

void set_tls_base(void* base) {
    asm {
        "mv tp, %0" : : "r"(base);
    }
}
