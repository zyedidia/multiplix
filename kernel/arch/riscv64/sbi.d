module kernel.arch.riscv64.sbi;

import ulib.option;

import ldc.llvmasm;

// This library defines an interface to a RISC-V SBI firmware implementation.
// Environment calls to the firmware are made with the "ecall" instruction. See
// the RISC-V Supervisor Binary Interface Specification for details.

struct SbiRet {
    uint error;
    uint value;
}

// dfmt off

// ecall with 3 args
SbiRet ecall(uint ext, uint fid, uintptr a0, uintptr a1, uintptr a2) {
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
SbiRet ecall(uint ext, uint fid, uintptr a0, uintptr a1) {
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
SbiRet ecall(uint ext, uint fid, uintptr a0) {
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
SbiRet ecall(uint ext, uint fid) {
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

    static uint getSpecVersion() {
        auto ret = ecall(ext, 0);
        return ret.value;
    }

    static uint getImplId() {
        auto ret = ecall(ext, 1);
        return ret.value;
    }

    static uint getImplVersion() {
        auto ret = ecall(ext, 2);
        return ret.value;
    }

    static bool probeExtension(uint extid) {
        auto ret = ecall(ext, 3, extid);
        return ret.value != 0;
    }

    static uint getMvendorId() {
        auto ret = ecall(ext, 4);
        return ret.value;
    }

    static uint getMarchId() {
        auto ret = ecall(ext, 5);
        return ret.value;
    }

    static uint getMimpId() {
        auto ret = ecall(ext, 6);
        return ret.value;
    }
}

struct Timer {
    enum ext = 0x54494D45;

    static bool supported() {
        return Base.probeExtension(ext);
    }

    static void setTimer(ulong val) {
        ecall(ext, 0, val);
    }
}

struct Reset {
    enum ext = 0x53525354;

    enum Type {
        shutdown = 0,
        coldReboot = 1,
        warmReboot = 2,
    }

    enum Reason {
        noReason = 0,
        failure = 1,
    }

    static bool supported() {
        return Base.probeExtension(ext);
    }

    static void systemReset(Type ty, Reason reason) {
        ecall(ext, 0, ty, reason);
    }

    static void reboot() {
        systemReset(Type.coldReboot, Reason.noReason);
    }

    static void shutdown() {
        systemReset(Type.shutdown, Reason.noReason);
    }
}

struct Hart {
    enum ext = 0x48534D;

    enum State {
        started = 0,
        stopped = 1,
        startPending = 2,
        stopPending = 3,
        suspended = 4,
        suspendPending = 5,
        resumePending = 6,
    }

    static bool supported() {
        return Base.probeExtension(ext);
    }

    private __gshared static Opt!uint _nharts;

    static uint nharts() {
        // Compute the number of harts by repeatedly asking if a hart exists.
        // This assumes that if hart n does not exist then all subsequent harts
        // do not exist, and that the first hart is 0.
        if (_nharts.has()) {
            return _nharts.get();
        }
        uint i;
        for (i = 0; exists(i); i++) {
        }
        _nharts = Opt!uint(i);
        return i;
    }

    // OpenSBI should give us the HART ID in a0 at boot-up, but when going
    // through u-boot first, it isn't obvious how to pass that parameter
    // through. To determine the HART ID for the first core to boot up we use
    // this function instead. It requests the status for every core and returns
    // the first one that is running. Since the first core to boot up will be
    // the only one running, that will be its ID. Subsequent cores are booted
    // directly via OpenSBI and get their HART ID passed in as a0.
    static uint getRunningId() {
        uint n = nharts();
        for (uint i = 0; i < n; i++) {
            if (getStatus(i) == State.started) {
                return i;
            }
        }
        assert(false, "no running hart found (impossible)");
    }

    static bool exists(uint hartid) {
        // ask for status, if error then hart does not exist
        auto r = ecall(ext, 2, hartid);
        return r.error == 0;
    }

    static uint getStatus(uint hartid) {
        auto r = ecall(ext, 2, hartid);
        return r.value;
    }

    static uint start(uint hartid, uintptr startAddr, uintptr opaque) {
        auto r = ecall(ext, 0, hartid, startAddr, opaque);
        return r.error;
    }
}

struct Step {
    enum ext = 0x0A000000;

    enum Check {
        ifence = (1 << 0),
        vmafence = (1 << 1),
        region = (1 << 2),
        mem = (1 << 3),
        equiv = (1 << 4),
        noecall = (1 << 5),
    }

    enum Region {
        device = (1 << 0),
        rdonly = (1 << 1),
        noexec = (1 << 2),
        stack = (1 << 3),
        rdwr = (1 << 4),
    }

    static bool enabled() {
        auto r = ecall(ext, 0);
        return r.value != 0;
    }

    static void enable(uint flags) {
        ecall(ext, 1, flags);
    }

    static void disable() {
        ecall(ext, 2);
    }

    static void markRegion(void* start, size_t sz, uint flags) {
        ecall(ext, 7, cast(uintptr)start, sz, flags);
    }

    static void enableAt(void* start, uint flags) {
        ecall(ext, 4, cast(uintptr)start, flags);
    }

    static void setHeap(void* start, size_t sz) {
        ecall(ext, 3, cast(uintptr)start, sz);
    }

    static int equivHash() {
        auto r = ecall(ext, 8);
        return r.value;
    }
}

struct Legacy {
    static void putchar(ubyte b) {
        enum ext = 0x01;
        ecall(ext, 0, b);
    }

    static uint getchar() {
        enum ext = 0x02;
        auto r = ecall(ext, 0);
        return r.error; // for legacy sbi functions a0 (error) contains the result
    }
}
