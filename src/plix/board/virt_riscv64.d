module plix.board.virt_riscv64;

import plix.dev.uart.virt : Virt;

struct machine {
    enum ncores = 4;
    enum mtime_freq = 3_580_000 * 2;
}

__gshared Virt uart = Virt(cast(Virt.Regs*) 0x10000000);

void setup() {}
