module kernel.sys;

version (visionfive) {
    public import kernel.board.visionfive.system;
}
version (qemuvirt) {
    public import kernel.board.qemuvirt.system;
}

enum highmemBase = 0xFFFF_FFC0_0000_0000;
enum gb(ulong n) = 1024 * 1024 * 1024 * n;
enum memsizePhysical = gb!(4);
enum pagesize = 4096;
