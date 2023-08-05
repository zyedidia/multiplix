module plix.arch.cpu;

version (RISCV64) {
    public import plix.arch.riscv64.cpu;
} else version (AArch64) {
    public import plix.arch.aarch64.cpu;
}
