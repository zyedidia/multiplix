module plix.trap;

import plix.arch.timer : Timer;
import plix.proc : Proc;

enum IrqType {
    timer,
}

void irq_handler(IrqType irq) {
    if (irq == IrqType.timer) {
        Timer.intr(Timer.time_slice_us);
    }
}

void irq_handler(Proc* p, IrqType irq) {
    irq_handler(irq);
}

enum FaultType {
    read,
    write,
    exec,
}

void pgflt_handler(Proc* p, void* addr, FaultType fault) {
}

noreturn unhandled(Proc* p) {
    while (1) {}
}
