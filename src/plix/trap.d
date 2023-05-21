module plix.trap;

import plix.timer : Timer;
import plix.proc : Proc;
import plix.schedule : ticks_queue;
import plix.syscall : sys_exit;
import plix.print : printf;

enum IrqType {
    timer,
}

void irq_handler(IrqType irq) {
    if (irq == IrqType.timer) {
        ticks_queue.wake_all();
        Timer.intr(Timer.time_slice);
    }
}

void irq_handler(Proc* p, IrqType irq) {
    irq_handler(irq);

    if (irq == IrqType.timer) {
        p.yield();
    }
}

enum FaultType {
    read,
    write,
    exec,
}

void pgflt_handler(Proc* p, void* addr, FaultType fault) {
    printf("%d: killed (page fault)\n", p.pid);
    sys_exit(p);
}

noreturn unhandled(Proc* p) {
    printf("%d: killed (unhandled)\n", p.pid);
    sys_exit(p);
}
