module kernel.irq;

import kernel.arch;

struct Irq {
    import kernel.cpu;

    // push_off and pop_off create an interrupt stack. Interrupts are disabled
    // when push_off is called, and are re-enabled after there have been as
    // many calls to pop_off as to push_off. The data for the stack is stored
    // in core-local storage.

    static void push_off() {
        bool old = ArchTrap.is_on();
        off();
        if (cpu.noff == 0)
            cpu.irqen = old;
        cpu.noff++;
    }

    static void pop_off() {
        assert(!ArchTrap.is_on());
        assert(cpu.noff >= 1);
        cpu.noff--;
        if (cpu.noff == 0 && cpu.irqen)
            on();
    }

    // Turn on interrupts.
    static void on() {
        ArchTrap.on();
    }

    // Turn off interrupts.
    static void off() {
        ArchTrap.off();
    }

    static bool is_on() {
        return ArchTrap.is_on();
    }
}
