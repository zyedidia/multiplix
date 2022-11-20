module kernel.board.visionfive.system;

import kernel.dev.uart.sbi;
import kernel.dev.reboot.sbi;
import kernel.dev.gpio.starfive;
import vm = kernel.vm;

alias Uart = SbiUart;
alias Reboot = SbiReboot;
alias Gpio = StarfiveGpio!(cast(uint*) vm.pa2ka(0x1191_0000));
