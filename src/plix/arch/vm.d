module plix.arch.vm;

version (RISCV64) {
    public import plix.arch.riscv64.vm;
} else version (AArch64) {
    public import plix.arch.aarch64.vm;
}
