module kernel.arch.riscv64.sbi;

import ulib.option;

// This library defines an interface to a RISC-V SBI firmware implementation.
// Environment calls to the firmware are made with the "ecall" instruction. See
// the RISC-V Supervisor Binary Interface Specification for details.

private struct SbiRet {
    uint error;
    uint value;
}

// dfmt off

// ecall with 3 args
private SbiRet ecall(uint ext, uint fid, uintptr arg0 = 0, uintptr arg1 = 0, uintptr arg2 = 0) {
    SbiRet ret;

    version (LDC) {
        import ldc.llvmasm;
        auto result = __asmtuple!(uint, uint) (
            "ecall",
            "={a0},={a1},{a7},{a6},{a0},{a1},{a2},~{memory}",
            ext, fid, arg0, arg1, arg2
        );
        ret.error = result.v[0];
        ret.value = result.v[1];
    }
    version (GNU) {
        import gcc.attributes;
        @register("a7") a7 = ext;
        @register("a6") a6 = fid;
        @register("a0") a0 = arg0;
        @register("a1") a1 = arg1;
        @register("a2") a2 = arg2;
        // cast to avoid unused variable linter warnings (linter doesn't see
        // the inline asm usage)
        cast(void) a7;
        cast(void) a6;
        cast(void) a0;
        cast(void) a1;
        cast(void) a2;
        asm {
            "ecall" : "+r"(a0), "+r"(a1) : "r"(a7), "r"(a6), "r"(a2) : "memory";
        }
        ret.error = cast(uint) a0;
        ret.value = cast(uint) a1;
    }

    return ret;
}

// dfmt on

struct Base {
    enum ext = 0x10;

    enum Fid {
        get_spec_version = 0,
        get_impl_id = 1,
        get_impl_version = 2,
        probe_extension = 3,
        get_mvendorid = 4,
        get_marchid = 5,
        get_mimpid = 6,
    }

    static uint get_spec_version() {
        auto ret = ecall(ext, Fid.get_spec_version);
        return ret.value;
    }

    static uint get_impl_id() {
        auto ret = ecall(ext, Fid.get_impl_id);
        return ret.value;
    }

    static uint get_impl_version() {
        auto ret = ecall(ext, Fid.get_impl_version);
        return ret.value;
    }

    static bool probe_extension(uint extid) {
        auto ret = ecall(ext, Fid.probe_extension, extid);
        return ret.value != 0;
    }

    static uint get_mvendorid() {
        auto ret = ecall(ext, Fid.get_mvendorid);
        return ret.value;
    }

    static uint get_marchid() {
        auto ret = ecall(ext, Fid.get_marchid);
        return ret.value;
    }

    static uint get_mimpid() {
        auto ret = ecall(ext, Fid.get_mimpid);
        return ret.value;
    }
}

struct Timer {
    enum ext = 0x54494D45;

    enum Fid {
        set_timer = 0,
    }

    static bool supported() {
        return Base.probe_extension(ext);
    }

    static void set_timer(ulong val) {
        cast() ecall(ext, Fid.set_timer, val);
    }
}

struct Hart {
    enum ext = 0x48534D;

    enum Fid {
        start = 0,
        start_all_cores = 128,
    }

    static uint start(uint hartid, uintptr addr, uintptr opaque) {
        auto r = ecall(ext, Fid.start, hartid, addr, opaque);
        return r.error;
    }

    static void start_all_cores() {
        cast() ecall(ext, Fid.start_all_cores);
    }
}

struct Debug {
    enum ext = 0x0A000000;

    enum Fid {
        enable = 0,
        enable_at = 1,
        disable = 2,
        alloc_heap = 3,
        vm_check = 4,
        vm_fence = 5,
        mark_alloc = 6,
        mark_free = 7,
    }

    // start checkers now
    static void enable() {
        cast() ecall(ext, Fid.enable);
    }

    // start checkers at addr
    // static void enable_at(uintptr addr) {
    //     cast() ecall(ext, Fid.enable_at, addr);
    // }

    static bool disable() {
        return ecall(ext, Fid.disable).value != 0;
    }

    static void alloc_heap(void* start, size_t size) {
        import kernel.vm;
        cast() ecall(ext, Fid.alloc_heap, ka2pa(cast(uintptr) start), size);
    }

    static void vm_check() {
        cast() ecall(ext, Fid.vm_check);
    }

    static void vm_fence() {
        cast() ecall(ext, Fid.vm_fence);
    }

    static void mark_alloc(uintptr addr, size_t size) {
        cast() ecall(ext, Fid.mark_alloc, addr, size);
    }

    static void mark_free(uintptr addr, size_t size) {
        cast() ecall(ext, Fid.mark_free, addr, size);
    }
}
