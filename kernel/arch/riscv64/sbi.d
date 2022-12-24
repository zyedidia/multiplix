module kernel.arch.riscv64.sbi;

import ulib.option;

import ldc.llvmasm;

// This library defines an interface to a RISC-V SBI firmware implementation.
// Environment calls to the firmware are made with the "ecall" instruction. See
// the RISC-V Supervisor Binary Interface Specification for details.

private struct SbiRet {
    uint error;
    uint value;
}

// dfmt off

// ecall with 3 args
private SbiRet ecall(uint ext, uint fid, uintptr a0, uintptr a1, uintptr a2) {
    SbiRet ret;

    auto result = __asmtuple!(uint, uint) (
        "ecall",
        "={a0},={a1},{a7},{a6},{a0},{a1},{a2},~{memory}",
        ext, fid, a0, a1, a2
    );
    ret.error = result.v[0];
    ret.value = result.v[1];

    return ret;
}

// ecall with 2 args
private SbiRet ecall(uint ext, uint fid, uintptr a0, uintptr a1) {
    SbiRet ret;

    auto result = __asmtuple!(uint, uint) (
        "ecall",
        "={a0},={a1},{a7},{a6},{a0},{a1},~{memory}",
        ext, fid, a0, a1
    );
    ret.error = result.v[0];
    ret.value = result.v[1];

    return ret;
}

// ecall with 1 arg
private SbiRet ecall(uint ext, uint fid, uintptr a0) {
    SbiRet ret;

    auto result = __asmtuple!(uint, uint) (
        "ecall",
        "={a0},={a1},{a7},{a6},{a0},~{memory}",
        ext, fid, a0,
    );
    ret.error = result.v[0];
    ret.value = result.v[1];

    return ret;
}

// ecall with no args
private SbiRet ecall(uint ext, uint fid) {
    SbiRet ret;

    auto result = __asmtuple!(uint, uint) (
        "ecall",
        "={a0},={a1},{a7},{a6},~{memory}",
        ext, fid
    );
    ret.error = result.v[0];
    ret.value = result.v[1];

    return ret;
}

// dfmt on

struct Base {
    enum ext = 0x10;

    static uint get_spec_version() {
        auto ret = ecall(ext, 0);
        return ret.value;
    }

    static uint get_impl_id() {
        auto ret = ecall(ext, 1);
        return ret.value;
    }

    static uint get_impl_version() {
        auto ret = ecall(ext, 2);
        return ret.value;
    }

    static bool probe_extension(uint extid) {
        auto ret = ecall(ext, 3, extid);
        return ret.value != 0;
    }

    static uint get_mvendorid() {
        auto ret = ecall(ext, 4);
        return ret.value;
    }

    static uint get_marchid() {
        auto ret = ecall(ext, 5);
        return ret.value;
    }

    static uint get_mimpid() {
        auto ret = ecall(ext, 6);
        return ret.value;
    }
}
