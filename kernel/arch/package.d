module kernel.arch;

version (RISCV64) {
    public import kernel.arch.riscv64.timer;
} else version (AArch64) {
    public import kernel.arch.aarch64.timer;
}
