module kernel.arch.riscv64;

public import kernel.arch.riscv64.timer;
public import kernel.arch.riscv64.boot;
public import kernel.arch.riscv64.tls;
public import kernel.arch.riscv64.trap;
public import kernel.arch.riscv64.regs;
public import kernel.arch.riscv64.vm;

import monitor = kernel.arch.riscv64.monitor.boot;
alias enter_kernel = monitor.enter_smode;
alias monitor_init = monitor.init;

import sbi = kernel.arch.riscv64.sbi;
alias Cpu = sbi.Hart;
alias Debug = sbi.Debug;

// arch-specific setup after booting
void setup() {}
