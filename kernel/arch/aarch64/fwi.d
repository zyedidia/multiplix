module kernel.arch.aarch64.fwi;

// dfmt off

private uint hvc(uint ext, uint fid, uintptr arg0 = 0, uintptr arg1 = 0, uintptr arg2 = 0) {
    version (LDC) {
        import ldc.llvmasm;
        return __asm!(uint) (
            "hvc 0",
            "={x0},{x7},{x6},{x0},{x1},{x2},~{memory},~{x1}",
            ext, fid, arg0, arg1, arg2
        );
    }
    version (GNU) {
        import gcc.attributes;
        @register("x7") x7 = ext;
        @register("x6") x6 = fid;
        @register("x0") x0 = arg0;
        @register("x1") x1 = arg1;
        @register("x2") x2 = arg2;
        // cast to avoid unused variable linter warnings (linter doesn't see
        // the inline asm usage)
        cast(void) x7;
        cast(void) x6;
        cast(void) x0;
        cast(void) x1;
        cast(void) x2;
        asm {
            "hvc 0" : "+r"(x0), "+r"(x1) : "r"(x7), "r"(x6), "r"(x2) : "memory";
        }
        return cast(uint) x0;
    }
}

// dfmt on

struct Cpu {
    enum ext = 0;

    enum Fid {
        start_all_cores = 0,
        enable_vm = 128,
    }

    static void start_all_cores() {
        cast() hvc(ext, Fid.start_all_cores);
    }

    static void enable_vm(uintptr ttbr) {
        cast() hvc(ext, Fid.enable_vm, ttbr);
    }
}

struct Debug {
    enum ext = 1;

    enum Fid {
        step_start = 0,
        step_start_at = 1,
        step_stop = 2,
    }

    // start single stepping now
    static void step_start() {
        cast() hvc(ext, Fid.step_start);
    }

    // start single stepping at addr
    static void step_start_at(uintptr addr) {
        cast() hvc(ext, Fid.step_start_at, addr);
    }

    // stop single stepping
    static void step_stop() {
        cast() hvc(ext, Fid.step_stop);
    }
}
