module plix.arch.timer;

version (RISCV64) {
    public import plix.arch.riscv64.timer;
} else version (AArch64) {
    public import plix.arch.aarch64.timer;
}
