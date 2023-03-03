module kernel.sanitizer;

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

import core.exception;
import ulib.string;
import gcc.attributes;

void handle_overflow(Overflow* data, ulong lhs, ulong rhs, char op) {
    panic(tostr(data.loc.file), ":", data.loc.line, ": integer overflow '", op, "'");
}

extern (C) {
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
        panic(tostr(data.loc.file), ":", data.loc.line, ": negate overflow");
    }

    void __ubsan_handle_divrem_overflow(Overflow* data, ulong a, ulong b) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": divrem overflow");
    }

    void __ubsan_handle_shift_out_of_bounds(ShiftOutOfBounds* data, ulong a, ulong b) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": shift out of bounds");
    }

    void __ubsan_handle_type_mismatch(TypeMismatch* data, ulong addr) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": type mismatch: ", Hex(addr));
    }

    void __ubsan_handle_type_mismatch_v1(TypeMismatch* data, ulong addr) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": type mismatch v1: ", Hex(addr), ", ", cast(int) data.type_check_kind, ", ", cast(int) data.alignment);
    }

    void __ubsan_handle_out_of_bounds(OutOfBounds* data, ulong index) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": out of bounds");
    }

    void __ubsan_handle_builtin_unreachable(SrcLoc* loc) {
        panic(tostr(loc.file), ":", loc.line, ": unreachable");
    }

    void __ubsan_handle_missing_return(SrcLoc* loc) {
        panic(tostr(loc.file), ":", loc.line, "missing return");
    }

    void __ubsan_handle_vla_bound_not_positive(VlaBound* data, ulong bound) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": vla bound not positive");
    }

    void __ubsan_handle_load_invalid_value(InvalidValue* data, void* val) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": load invalid value");
    }

    void __ubsan_handle_nonnull_arg(NonnullArg* data) {
        panic(tostr(data.loc.file), ":", data.loc.line, ": nonnull arg");
    }

    void __ubsan_handle_nonnull_return(SrcLoc *loc) {
        panic(tostr(loc.file), ":", loc.line, ": nonnull return");
    }

    void __ubsan_handle_pointer_overflow(SrcLoc *loc, uintptr base, uintptr result) {
        panic(tostr(loc.file), ":", loc.line, ": pointer overflow");
    }
}
