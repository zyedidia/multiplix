module kernel.arch;

version (RISCV64) {
    import kernel.arch.riscv64.monitor.boot;
    alias enter_kernel = enter_smode;
    alias monitor_init = init;
    import sbi = kernel.arch.riscv64.sbi;
    alias Cpu = sbi.Hart;

    public import kernel.arch.riscv64;
} else version (AArch64) {
    import kernel.arch.aarch64.monitor.boot;
    alias enter_kernel = enter_el1;
    alias monitor_init = init;
    import fwi = kernel.arch.aarch64.fwi;
    alias Cpu = fwi.Cpu;

    public import kernel.arch.aarch64;
}
