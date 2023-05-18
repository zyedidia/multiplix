module plix.schedule;

import plix.proc : Proc;

struct Queue {
    Proc* front;
    Proc* back;
    usize size;

    void push_front(Proc* p) {

    }

    void remove(Proc* p) {

    }

    Proc* pop_back() {
        return null;
    }

    void wake_all() {

    }

    void wake(Proc* p) {
        remove(p);
    }
}
