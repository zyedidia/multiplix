module kernel.irq;

import kernel.arch;

struct Irq {
    import kernel.cpu;
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
