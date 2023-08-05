module plix.arch.monitor.boot;

version (RISCV64) {
    public import plix.arch.riscv64.monitor.boot;
} else version (AArch64) {
    public import plix.arch.aarch64.monitor.boot;
}
