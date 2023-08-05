module plix.arch.cache;

version (RISCV64) {
    public import plix.arch.riscv64.cache;
} else version (AArch64) {
    public import plix.arch.aarch64.cache;
}
