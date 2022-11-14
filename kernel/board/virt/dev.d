module kernel.board.virt.dev;

import dev = kernel.dev;

alias SysCon = dev.SysCon!(cast(uint*) 0x100000);
alias Uart = dev.Ns16550!(cast(uint*) 0x10000000);
