module kernel.arch.aarch64.fwi;

import ldc.llvmasm;

// dfmt off

private uint hvc(uint fid, uintptr a0, uintptr a1, uintptr a2) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x0},{x1},{x2},~{memory}",
        fid, a0, a1, a2
    );
}
private uint hvc(uint fid, uintptr a0, uintptr a1) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x0},{x1},~{memory}",
        fid, a0, a1
    );
}
private uint hvc(uint fid, uintptr a0) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},{x0},~{memory}",
        fid, a0
    );
}
private uint hvc(uint fid) {
    return __asm!(uint) (
        "hvc 0",
        "={x0},{x7},~{memory}",
        fid
    );
}

// dfmt on

struct Cpu {
    enum Fid {
        start_all_cores = 0,
    }

    static void start_all_cores() {
        cast() hvc(Fid.start_all_cores);
    }
}
