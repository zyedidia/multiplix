module plix.schedule;

import plix.proc : Proc, ProcState;
import plix.arch.trap : Irq;
import plix.arch.cpu : wfi;
import plix.arch.regs : Context;

struct Queue {
    Proc* front;
    Proc* back;
    usize size;

    void push_front(Proc* p) {
        p.next = front;
        p.prev = null;
        if (front != null) {
            front.prev = p;
        } else {
            back = p;
        }
        front = p;
        size++;
    }

    void remove(Proc* p) {
        if (p.next != null) {
            p.next.prev = p.prev;
        } else {
            back = p.prev;
        }
        if (p.prev != null) {
            p.prev.next = p.next;
        } else {
            front = p.next;
        }
        size--;
    }

    Proc* pop_back() {
        if (back == null) {
            return null;
        }
        Proc* b = back;
        remove(b);
        return b;
    }

    void wake_all() {
        while (front) {
            // removes front from the queue
            wake(front);
        }
    }

    void wake(Proc* p) {
        assert(p.state == ProcState.blocked);
        remove(p);
        p.state = ProcState.runnable;
        runq.push_front(p);
    }
}

// Returns the next process available to run, or blocks waiting for a process
// to become available.
Proc* runnable_proc() {
    // Enable interrupts to avoid deadlock if there are no runnable processes.
    Irq.on();

    while (true) {
        Proc* p = runq.pop_back();
        if (p) {
            return p;
        }
        wfi();
    }
}

extern (C) void kswitch(Proc* p, Context* oldctx, Context* newctx);

__gshared Queue runq;
__gshared Queue exit_queue;
__gshared Queue ticks_queue;
__gshared Context scheduler;

void schedule() {
    while (true) {
        Proc* p = runnable_proc();

        Irq.off();
        kswitch(p, &scheduler, &p.context);

        if (p.state == ProcState.runnable) {
            runq.push_front(p);
        }
    }
}
