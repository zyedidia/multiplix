module plix.arch.aarch64.monitor;

usize monitor_call(usize fn, usize arg0 = 0, usize arg1 = 0, usize arg2 = 0) {
    version (LDC) {
        import ldc.llvmasm;
        return __asm!(usize) (
            "hvc 0",
            "={x0},{x7},{x0},{x1},{x2},~{memory}",
            fn, arg0, arg1, arg2
        );
    }
    version (GNU) {
        import gcc.attributes;
        @register("x7") usize x7 = fn;
        @register("x0") usize x0 = arg0;
        @register("x1") usize x1 = arg1;
        @register("x2") usize x2 = arg2;
        // cast to avoid unused variable linter warnings (linter doesn't see
        // the inline asm usage)
        cast(void) x7;
        cast(void) x1;
        cast(void) x2;
        asm {
            "hvc 0" : "+r"(x0) : "r"(x7), "r"(x1), "r"(x2) : "memory";
        }
        return x0;
    }
}
