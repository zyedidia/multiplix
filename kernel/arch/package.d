module kernel.arch;

version (RISCV64) {
    import kernel.arch.riscv64.monitor.boot;
    alias enter_kernel = enter_smode;

    public import kernel.arch.riscv64;
} else version (AArch64) {
    import kernel.arch.aarch64.monitor.boot;
    alias enter_kernel = enter_el1;

    public import kernel.arch.aarch64;
}
