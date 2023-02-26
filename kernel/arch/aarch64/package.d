module kernel.arch.aarch64;

public import kernel.arch.aarch64.timer;
public import kernel.arch.aarch64.boot;
public import kernel.arch.aarch64.tls;
public import kernel.arch.aarch64.trap;
public import kernel.arch.aarch64.regs;
public import kernel.arch.aarch64.vm;

import monitor = kernel.arch.aarch64.monitor.boot;
alias enter_kernel = monitor.enter_el1;
alias monitor_init = monitor.init;

import fwi = kernel.arch.aarch64.fwi;
alias Cpu = fwi.Cpu;
alias Debug = fwi.Debug;

// arch-specific setup after booting
void setup() {
    // enable vm and caches in EL2
    import kernel.arch.aarch64.sysreg;
    // fwi.Cpu.enable_vm(SysReg.ttbr0_el1);

    import bits = ulib.bits;
    // Enable cycle counter.
    SysReg.pmcr_el0 = 1;
    SysReg.pmcntenset_el0 = 1 << 31;
}
