module kernel.check.icache;

// The I-cache checker ensures that the kernel does not execute pages that have
// been written without first synchronizing the instruction and data caches.

struct IcacheChecker {
    static void on_store(void* addr, uint size) {

    }

    static void on_exec(void* pc) {

    }
}
