module kernel.check.mem;

import core.exception;
import kernel.alloc;

import libc;

struct MemChecker {
    ubyte[] shadow;
    uintptr mem_base;

    void initialize(uintptr mem_base, size_t mem_size) {
        ubyte* mem = cast(ubyte*) kalloc(mem_size);
        check(mem != null);
        this.mem_base = mem_base;
        this.shadow = mem[0 .. mem_size];
    }

    void on_access(uintptr addr, size_t size) {
        // TODO: use memcmp or something more efficient
        for (size_t i = 0; i < size; i++) {
            if (shadow[addr + i - mem_base] != 1) {
                panicf("mem checker: out of bounds access at %p\n", cast(void*) addr);
            }
        }
    }

    void mark_alloc(uintptr addr, size_t size) {
        memset(&shadow[addr - mem_base], 1, size);
    }

    void mark_free(uintptr addr, size_t size) {
        memset(&shadow[addr - mem_base], 0, size);
    }
}
