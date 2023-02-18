module core.sync;

pragma(inline, true)
void inv_dcache()(ubyte* start, size_t size) {
    version (RISCV64) {
        // haven't had any need to flush the dcache on riscv
        static assert(0, "TODO: clean_dcache not implemented for RISC-V");
    } else version (AArch64) {
        for (size_t i = 0; i < size; i++) {
            asm {
                "dc civac, %0" :: "r"(start + i);
            }
        }
    }
}

pragma(inline, true)
void clean_dcache()(ubyte* start, size_t size) {
    version (RISCV64) {
        // haven't had any need to flush the dcache on riscv
        static assert(0, "TODO: clean_dcache not implemented for RISC-V");
    } else version (AArch64) {
        for (size_t i = 0; i < size; i++) {
            asm {
                "dc cvau, %0" :: "r"(start + i);
            }
        }
    }
}

pragma(inline, true)
void clean_icache()(ubyte* start, size_t size) {
    version (RISCV64) {
        // haven't had any need to flush the icache on riscv
        static assert(0, "TODO: clean_icache not implemented for RISC-V");
    } else version (AArch64) {
        for (size_t i = 0; i < size; i++) {
            asm {
                "ic ivau, %0" :: "r"(start + i);
            }
        }
    }
}

// Synchronize instruction and data memory in range
pragma(inline, true)
void sync_idmem(ubyte* start, size_t size) {
    version (RISCV64) {
        insn_fence();
    } else version (AArch64) {
        clean_dcache(start, size);
        sync_fence();
        clean_icache(start, size);
        sync_fence();
        insn_fence();
    }
}

pragma(inline, true)
void insn_fence() {
    version (RISCV64) {
        asm {
            "fence.i" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "isb sy" ::: "memory";
        }
    }
}

pragma(inline, true)
void device_fence() {
    version (RISCV64) {
        asm {
            "fence" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "dsb sy" ::: "memory";
        }
    }
}

pragma(inline, true)
void sync_fence() {
    version (RISCV64) {
        asm {
            "fence" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "dsb ish" ::: "memory";
        }
    }
}

pragma(inline, true)
void vm_fence() {
    version (RISCV64) {
        asm {
            "sfence.vma" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "dsb ish" ::: "memory";
            "tlbi vmalle1" ::: "memory";
            "dsb ish" ::: "memory";
            "isb" ::: "memory";
        }
    }
}

pragma(inline, true)
void compiler_fence() {
    asm {
        "" ::: "memory";
    }
}

version (LDC) {
    enum AtomicOrdering {
      NotAtomic = 0,
      Unordered = 1,
      Monotonic = 2,
      Consume = 3,
      Acquire = 4,
      Release = 5,
      AcquireRelease = 6,
      SequentiallyConsistent = 7
    }
    alias DefaultOrdering = AtomicOrdering.SequentiallyConsistent;

    enum SynchronizationScope {
      SingleThread = 0,
      CrossThread  = 1,
      Default = CrossThread
    }

    enum AtomicRmwSizeLimit = size_t.sizeof;


    /// Used to introduce happens-before edges between operations.
    pragma(LDC_fence)
        void memory_fence(AtomicOrdering ordering = DefaultOrdering,
                          SynchronizationScope syncScope = SynchronizationScope.Default);

    /// Atomically stores val in memory at ptr.
    pragma(LDC_atomic_store)
        void atomic_store(T)(T val, shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

    struct CmpXchgResult(T) {
        T previousValue;
        bool exchanged;
    }

    /// Loads a value from memory at ptr and compares it to cmp.
    /// If they are equal, it stores val in memory at ptr.
    /// This is all performed as single atomic operation.
    pragma(LDC_atomic_cmp_xchg)
        CmpXchgResult!T atomic_cmp_xchg(T)(
            shared T* ptr, T cmp, T val,
            AtomicOrdering successOrdering = DefaultOrdering,
            AtomicOrdering failureOrdering = DefaultOrdering,
            bool weak = false);

    /// Atomically sets *ptr += val and returns the previous *ptr value.
    pragma(LDC_atomic_rmw, "add")
        T atomic_rmw_add(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);
}
