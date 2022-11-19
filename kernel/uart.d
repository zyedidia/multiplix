module kernel.uart;

import sbi = kernel.arch.riscv.sbi;
import kernel.arch.riscv.timer;

void tx(ubyte b) {
    sbi.legacy_putchar(b);
}

ubyte rx() {
    uint c;
    do {
        c = sbi.legacy_getchar();
    } while(c > ubyte.max);
    return cast(ubyte) c;
}

void tx_flush() {}

bool rx_empty() {
    return false;
}
