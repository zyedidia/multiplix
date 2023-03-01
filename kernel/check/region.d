module kernel.checker.region;

// The region checker ensures that the kernel does not write to read-only
// regions, and that accesses to distinct device regions are separated by
// fences.

enum Region {
    rdonly,
    device,
}

struct RegionChecker {
    static void mark_region(void* start, size_t size, Region type) {

    }

    static void on_load(void* pc, void* addr, uint size) {

    }

    static void on_store(void* pc, void* addr, ulong val, uint size) {

    }

    static void on_fence() {

    }
}
