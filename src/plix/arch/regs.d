module plix.arch.regs;

version (RISCV64) {
    public import plix.arch.riscv64.regs;
} else version (AArch64) {
    public import plix.arch.aarch64.regs;
}
