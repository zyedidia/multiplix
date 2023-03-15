module kernel.check.mem;

struct MemChecker {
    ubyte[] shadow;
    uintptr mem_base;

    void initialize(uintptr mem_base, size_t mem_size) {

    }

    void on_access(uintptr addr, size_t size) {

    }

    void mark_alloc(uintptr addr, size_t size) {

    }

    void mark_free(uintptr addr, size_t size) {

    }
}
