module kernel.board.visionfive.system;

import kernel.dev.uart.sbi;
import kernel.dev.reboot.sbi;

alias Uart = SbiUart;
alias Reboot = SbiReboot;
