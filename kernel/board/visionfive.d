module kernel.board.visionfive;

import kernel.dev.uart.dw8250;

alias Uart = Dw8250!(0x12440000);
