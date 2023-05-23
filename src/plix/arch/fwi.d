module plix.arch.fwi;

version (RISCV64) {
    public import plix.arch.riscv64.fwi;
} else version (AArch64) {
    public import plix.arch.aarch64.fwi;
}
