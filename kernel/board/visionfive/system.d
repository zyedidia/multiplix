module kernel.board.visionfive.system;

import kernel.dev.uart.dw8250;
import kernel.dev.reboot.sbi;
import kernel.dev.gpio.starfive;
import vm = kernel.vm;

alias Uart = Dw8250!(0x12440000);
alias Reboot = SbiReboot;
alias Gpio = StarfiveGpio!(cast(uint*) vm.pa2ka(0x1191_0000));
