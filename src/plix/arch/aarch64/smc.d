module plix.arch.aarch64.smc;

usize smc_call(uint fn, ulong arg0 = 0, ulong arg1 = 0, ulong arg2 = 0) {
    version (LDC) {
        import ldc.llvmasm;
        return __asm!(usize) (
            "smc 0",
            "={x0},{x0},{x1},{x2},{x3},~{memory},~{x4},~{x5},~{x6},~{x7},~{x8}," ~
                "~{x9},~{x10},~{x11},~{x12},~{x13},~{x14},~{x15},~{x16},~{x17}",
            fn, arg0, arg1, arg2
        );
    }
    version (GNU) {
        import gcc.attributes;
        @register("x0") usize x0 = fn;
        @register("x1") usize x1 = arg0;
        @register("x2") usize x2 = arg1;
        @register("x3") usize x3 = arg2;
        // cast to avoid unused variable linter warnings (linter doesn't see
        // the inline asm usage)
        cast(void) x1;
        cast(void) x2;
        cast(void) x3;
        asm {
            "smc 0" : "+r"(x0) : "r"(x1), "r"(x2), "r"(x3) : "x4", "x5", "x6",
                "x7", "x8", "x9", "x10", "x11", "x12", "x13", "x14", "x15",
                "x16", "x17", "memory";
        }
        return x0;
    }
}

long cpu_on(ulong target_cpu, ulong entry, ulong context) {
    return cast(long) smc_call(0xc400_0003, target_cpu, entry, context);
}

long affinity_info(ulong target_cpu, uint lowest_affinity) {
    return cast(long) smc_call(0xc400_0004, target_cpu, lowest_affinity);
}
