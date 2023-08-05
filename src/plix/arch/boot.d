module plix.arch.boot;

version (RISCV64) {
    public import plix.arch.riscv64.boot;
} else version (AArch64) {
    public import plix.arch.aarch64.boot;
}
