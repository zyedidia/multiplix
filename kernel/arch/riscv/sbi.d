module kernel.arch.riscv.sbi;

struct SbiRet {
    uint error;
    uint value;
}

private SbiRet ecall(int ext, int fid, uintptr a0,
                        uintptr a1, uintptr a2,
                        uintptr a3, uintptr a4,
                        uintptr a5) {
        SbiRet ret;

        asm {
            "ecall"
              : "r" (a0), "r" (a1)
              : "r" (a2), "r" (a3), "r" (a4), "r" (a5), "r" (fid), "r" (ext)
              : "memory";
        }
        ret.error = cast(uint)a0;
        ret.value = cast(uint)a1;

        return ret;
}

struct Base {
    enum ext = 0x10;

    static uint get_spec_version() {
        auto ret = ecall(ext, 0,
                0, 0, 0, 0, 0, 0);
        return ret.value;
    }

    static uint get_impl_id() {
        auto ret = ecall(ext, 1,
                0, 0, 0, 0, 0, 0);
        return ret.value;
    }

    static uint get_impl_version() {
        auto ret = ecall(ext, 2,
                0, 0, 0, 0, 0, 0);
        return ret.value;
    }

    static bool probe_extension(uint extid) {
        auto ret = ecall(ext, 3,
                0, 0, 0, 0, 0, 0);
        return ret.value != 0;
    }

    static uint get_mvendorid() {
        auto ret = ecall(ext, 4,
                0, 0, 0, 0, 0, 0);
        return ret.value;
    }

    static uint get_marchid() {
        auto ret = ecall(ext, 5,
                0, 0, 0, 0, 0, 0);
        return ret.value;
    }

    static uint get_mimpid() {
        auto ret = ecall(ext, 6,
                0, 0, 0, 0, 0, 0);
        return ret.value;
    }
}

struct Timer {
    enum ext = 0x54494D45;

    static void set_timer(ulong stime_value) {
        ecall(ext, 0,
                0, 0, 0, 0, 0, 0);
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
        ecall(ext, 0,
                0, 0, 0, 0, 0, 0);
    }

    static void reboot() {
        system_reset(Type.cold_reboot, Reason.no_reason);
    }

    static void shutdown() {
        system_reset(Type.shutdown, Reason.no_reason);
    }
}
