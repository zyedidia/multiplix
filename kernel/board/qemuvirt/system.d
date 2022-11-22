module kernel.board.qemuvirt.system;

import kernel.dev.uart.ns16550;
import kernel.dev.reboot.syscon;
import kernel.vm;

alias Reboot = SysCon!(cast(uint*) pa2ka(0x100000));
alias Uart = Ns16550!(cast(uint*) pa2ka(0x10000000));
