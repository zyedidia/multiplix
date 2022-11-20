module kernel.board.qemuvirt.system;

import kernel.dev.uart.ns16550;
import kernel.dev.reboot.syscon;

alias Reboot = SysCon!(cast(uint*) 0x100000);
alias Uart = Ns16550!(cast(uint*) 0x10000000);
