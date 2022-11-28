module kernel.arch;

// we only support riscv64
import riscv64 = kernel.arch.riscv64;

alias setTlsBase = riscv64.setTlsBase;
alias Pagetable = riscv64.Pagetable39;
alias Pte = riscv64.Pte39;
alias Regs = riscv64.Regs;
alias Trap = riscv64.Trap;
alias Perm = riscv64.Perm;
alias Trapframe = riscv64.Trapframe;
