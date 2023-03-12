module kernel.sanitizer;

import core.exception;
import ulib.string;
import gcc.attributes;

// Support for UBSAN and ASAN.

version (sanitizer):
version (GNU):

struct SrcLoc {
    const char* file;
    uint line;
    uint col;
}

struct TypeDesc {
    ushort kind;
    ushort info;
    char[1] name;
}

struct OutOfBounds {
    SrcLoc loc;
    const TypeDesc* array_type;
    const TypeDesc* index_type;
}

struct ShiftOutOfBounds {
    SrcLoc loc;
    const TypeDesc* lhs_type;
    const TypeDesc* rhs_type;
}

struct NonnullArg {
    SrcLoc loc;
    SrcLoc attr_loc;
    int arg_index;
}

struct TypeData {
    SrcLoc loc;
    TypeDesc* type;
}

struct TypeMismatch {
    SrcLoc loc;
    TypeDesc* type;
    ubyte alignment;
    ubyte type_check_kind;
}

alias Overflow = TypeData;
alias InvalidValue = TypeData;
alias VlaBound = TypeData;

@no_sanitize("kernel-address", "undefined")
void handle_overflow(Overflow* data, ulong lhs, ulong rhs, char op) {
    panicf("%s:%d: integer overflow '%c'\n", data.loc.file, data.loc.line, op);
}

extern (C) {
    @no_sanitize("kernel-address", "undefined"):
    // otherwise these are removed by LTO before instrumentation happens
    @used:
    void __ubsan_handle_add_overflow(Overflow* data, ulong a, ulong b) {
        handle_overflow(data, a, b, '+');
    }

    void __ubsan_handle_sub_overflow(Overflow* data, ulong a, ulong b) {
        handle_overflow(data, a, b, '-');
    }

    void __ubsan_handle_mul_overflow(Overflow* data, ulong a, ulong b) {
        handle_overflow(data, a, b, '*');
    }

    void __ubsan_handle_negate_overflow(Overflow* data, ulong a) {
        panicf("%s:%d: negate overflow\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_divrem_overflow(Overflow* data, ulong a, ulong b) {
        panicf("%s:%d: devrem overflow\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_shift_out_of_bounds(ShiftOutOfBounds* data, ulong a, ulong b) {
        panicf("%s:%d: shift out of bounds\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_type_mismatch(TypeMismatch* data, ulong addr) {
        panicf("%s:%d: type mismatch %lx\n", data.loc.file, data.loc.line, addr);
    }

    void __ubsan_handle_type_mismatch_v1(TypeMismatch* data, ulong addr) {
        panicf("%s:%d: type mismatch v1: addr: %lx, kind: %d, align: %d\n", data.loc.file, data.loc.line, addr, data.type_check_kind, data.alignment);
    }

    void __ubsan_handle_out_of_bounds(OutOfBounds* data, ulong index) {
        panicf("%s:%d: out of bounds\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_builtin_unreachable(SrcLoc* loc) {
        panicf("%s:%d: unreachable\n", loc.file, loc.line);
    }

    void __ubsan_handle_missing_return(SrcLoc* loc) {
        panicf("%s:%d: missing return\n", loc.file, loc.line);
    }

    void __ubsan_handle_vla_bound_not_positive(VlaBound* data, ulong bound) {
        panicf("%s:%d: vla bound not positive\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_load_invalid_value(InvalidValue* data, void* val) {
        panicf("%s:%d: load invalid value\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_nonnull_arg(NonnullArg* data) {
        panicf("%s:%d: nonnull arg\n", data.loc.file, data.loc.line);
    }

    void __ubsan_handle_nonnull_return(SrcLoc *loc) {
        panicf("%s:%d: nonnull return\n", loc.file, loc.line);
    }

    void __ubsan_handle_pointer_overflow(SrcLoc *loc, uintptr base, uintptr result) {
        panicf("%s:%d: pointer overflow\n", loc.file, loc.line);
    }
}

// ASAN

extern (C) extern immutable uint _kcode_start, _kcode_end, _krodata_start, _krodata_end;

@no_sanitize("kernel-address", "undefined"):
void asan_access(uintptr addr, size_t size, bool write, void* retaddr) {
    bool in_range(uintptr addr, size_t size, immutable uint* start, immutable uint* end) {
        return addr+size >= cast(uintptr) start && addr < cast(uintptr) end;
    }

    import sys = kernel.sys;
    if (addr < sys.pagesize) {
        panicf("%s of null page: %lx (at %p)\n", write ? "write".ptr : "read".ptr, addr, retaddr);
    }

    if (in_range(addr, size, &_kcode_start, &_kcode_end) && write) {
        panicf("write of size %ld to kernel code: %lx (at %p)\n", size, addr, retaddr);
    }
    if (in_range(addr, size, &_krodata_start, &_krodata_end) && write) {
        panicf("write of size %ld to kernel read-only data: %lx (at %p)\n", size, addr, retaddr);
    }
}

extern (C) {
    @no_sanitize("kernel-address", "undefined"):
    @used:
    import core.builtins;
    void __asan_load1_noabort(uintptr addr) {
        asan_access(addr, 1, false, return_address(0));
    }
    void __asan_load2_noabort(uintptr addr) {
        asan_access(addr, 2, false, return_address(0));
    }
    void __asan_load4_noabort(uintptr addr) {
        asan_access(addr, 4, false, return_address(0));
    }
    void __asan_load8_noabort(uintptr addr) {
        asan_access(addr, 8, false, return_address(0));
    }
    void __asan_load16_noabort(uintptr addr) {
        asan_access(addr, 16, false, return_address(0));
    }
    void __asan_loadN_noabort(uintptr addr, size_t sz) {
        asan_access(addr, sz, false, return_address(0));
    }

    void __asan_store1_noabort(uintptr addr) {
        asan_access(addr, 1, true, return_address(0));
    }
    void __asan_store2_noabort(uintptr addr) {
        asan_access(addr, 2, true, return_address(0));
    }
    void __asan_store4_noabort(uintptr addr) {
        asan_access(addr, 4, true, return_address(0));
    }
    void __asan_store8_noabort(uintptr addr) {
        asan_access(addr, 8, true, return_address(0));
    }
    void __asan_store16_noabort(uintptr addr) {
        asan_access(addr, 16, true, return_address(0));
    }
    void __asan_storeN_noabort(uintptr addr, size_t sz) {
        asan_access(addr, sz, true, return_address(0));
    }

    void __asan_handle_no_return() {}
    void __asan_before_dynamic_init(const char* module_name) {}
    void __asan_after_dynamic_init() {}
}
