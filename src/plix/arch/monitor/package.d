module plix.arch.monitor;

version (RISCV64) {
    public import plix.arch.riscv64.monitor;
} else version (AArch64) {
    public import plix.arch.aarch64.monitor;
}
