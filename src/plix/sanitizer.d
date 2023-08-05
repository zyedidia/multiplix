module plix.sanitizer;

version (GNU):
version (sanitizer):

import gcc.attributes;
import core.exception : panicf;

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
