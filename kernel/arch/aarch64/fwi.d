module kernel.arch.aarch64.fwi;

import ldc.llvmasm;

// dfmt off

private uint hvc(uint ext, uint fid, uintptr a0, uintptr a1, uintptr a2) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x6},{x0},{x1},{x2},~{memory}",
        ext, fid, a0, a1, a2
    );
}
private uint hvc(uint ext, uint fid, uintptr a0, uintptr a1) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x6},{x0},{x1},~{memory}",
        ext, fid, a0, a1
    );
}
private uint hvc(uint ext, uint fid, uintptr a0) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x6},{x0},~{memory}",
        ext, fid, a0
    );
}
private uint hvc(uint ext, uint fid) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x6},~{memory}",
        ext, fid
    );
}

// dfmt on

struct Cpu {
    enum ext = 0;

    enum Fid {
        start_all_cores = 0,
    }

    static void start_all_cores() {
        cast() hvc(ext, Fid.start_all_cores);
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

    static void step_stop() {
        cast() hvc(ext, Fid.step_stop);
    }
}
