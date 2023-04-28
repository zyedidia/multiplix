module plix.arch.trap;

version (RISCV64) {
    public import plix.arch.riscv64.trap;
} else version (AArch64) {
    public import plix.arch.aarch64.trap;
}
