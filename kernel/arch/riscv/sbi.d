module kernel.arch.riscv.sbi;

import ldc.llvmasm;

struct SbiRet {
    uint error;
    uint value;
}

SbiRet ecall(int ext, int fid, uintptr a0, uintptr a1) {
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

SbiRet ecall(int ext, int fid, uintptr a0) {
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

SbiRet ecall(int ext, int fid) {
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

struct Timer {
    enum ext = 0x54494D45;

    static void set_timer(ulong stime_value) {
        ecall(ext, 0, stime_value);
    }
}

struct Reset {
    enum ext = 0x53525354;

    enum Type {
        shutdown = 0,
        cold_reboot = 1,
        warm_reboot = 2,
    }

    enum Reason {
        no_reason = 0,
        failure = 1,
    }

    static void system_reset(Type ty, Reason reason) {
        ecall(ext, 0, ty, reason);
    }

    static void reboot() {
        system_reset(Type.cold_reboot, Reason.no_reason);
    }

    static void shutdown() {
        system_reset(Type.shutdown, Reason.no_reason);
    }
}

void legacy_putchar(ubyte b) {
    enum ext = 0x01;
    ecall(ext, 0, b);
}

uint legacy_getchar() {
    enum ext = 0x02;
    auto r = ecall(ext, 0);
    return r.error; // for legacy sbi functions a0 (error) contains the result
}
