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
        step_start = 0,
        step_start_at = 1,
        step_stop = 2,
    }

    // start single stepping now
    static void step_start() {
        cast() ecall(ext, Fid.step_start);
    }

    // start single stepping at addr
    static void step_start_at(uintptr addr) {
        cast() ecall(ext, Fid.step_start_at, addr);
    }

    static void step_stop() {
        cast() ecall(ext, Fid.step_stop);
    }
}
