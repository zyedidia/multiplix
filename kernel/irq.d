module kernel.irq;

import kernel.arch;

struct Irq {
    static int noff;   // depth of push_off
    static bool irqen; // were irqs enabled before push_off

    static void push_off() {
        bool old = ArchTrap.is_on();
        off();
        if (noff == 0)
            irqen = old;
        noff++;
    }

    static void pop_off() {
        assert(!ArchTrap.is_on());
        assert(noff >= 1);
        noff--;
        if (noff == 0 && irqen)
            on();
    }

    static void on() {
        ArchTrap.on();
    }

    static void off() {
        ArchTrap.off();
    }

    static bool is_on() {
        return ArchTrap.is_on();
    }
}
