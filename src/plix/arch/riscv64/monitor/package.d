module plix.arch.riscv64.monitor;

usize monitor_call(usize fn, usize arg0 = 0, usize arg1 = 0, usize arg2 = 0) {
    version (LDC) {
        import ldc.llvmasm;
        return __asm!(usize) (
            "ecall",
            "={a0},{a7},{a0},{a1},{a2},~{memory}",
            fn, arg0, arg1, arg2
        );
    }
    version (GNU) {
        import gcc.attributes;
        @register("a7") usize a7 = fn;
        @register("a0") usize a0 = arg0;
        @register("a1") usize a1 = arg1;
        @register("a2") usize a2 = arg2;
        // cast to avoid unused variable linter warnings (linter doesn't see
        // the inline asm usage)
        cast(void) a7;
        cast(void) a1;
        cast(void) a2;
        asm {
            "ecall" : "+r"(a0) : "r"(a7), "r"(a1), "r"(a2) : "memory";
        }
        return a0;
    }
}
