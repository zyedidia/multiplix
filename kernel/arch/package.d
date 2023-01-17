module kernel.arch;

version (RISCV64) {
    public import kernel.arch.riscv64;
} else version (AArch64) {
    public import kernel.arch.aarch64;
}
