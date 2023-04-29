module plix.board.virt_riscv64;

import plix.dev.uart.virt : Virt;
import plix.dev.irq.clint : Clint;

struct Machine {
    enum ncores = 4;
    enum mtime_freq = 3_580_000 * 2;
}

__gshared Virt uart = Virt(cast(Virt.Regs*) 0x1000_0000);
__gshared Clint clint = Clint(0x200_0000);

void setup() {}
