module board.virt.dev;

static import dev;

alias SysCon = dev.SysCon!(cast(uint*) 0x100000);
alias Uart = dev.Ns16550!(cast(uint*) 0x10000000);
