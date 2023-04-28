module plix.arch.aarch64.trap;

struct irq {
    static void set_handler(void function() handler) {
    }

    static void on() {
    }

    static void off() {
    }

    static bool enabled() {
        return false;
    }
}
