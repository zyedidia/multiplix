module core.sync;

//
// ATOMIC OPERATIONS AND SYNCHRONIZATION INTRINSICS
//

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

pragma(inline, true)
alias clean_dcache() = (ubyte* start, size_t size) {
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
};

pragma(inline, true)
alias clean_icache() = (ubyte* start, size_t size) {
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
};

// Synchronize instruction and data memory in range
pragma(inline, true)
alias sync_idmem = (ubyte* start, size_t size) {
    version (RISCV64) {
        insn_fence();
    } else version (AArch64) {
        clean_dcache(start, size);
        sync_fence();
        clean_icache(start, size);
        sync_fence();
        insn_fence();
    }
};

pragma(inline, true)
alias insn_fence = () {
    version (RISCV64) {
        asm {
            "fence.i" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "isb sy" ::: "memory";
        }
    }
};

pragma(inline, true)
alias device_fence = () {
    version (RISCV64) {
        asm {
            "fence" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "dsb sy" ::: "memory";
        }
    }
};

pragma(inline, true)
alias sync_fence = () {
    version (RISCV64) {
        asm {
            "fence" ::: "memory";
        }
    } else version (AArch64) {
        asm {
            "dsb ish" ::: "memory";
        }
    }
};

pragma(inline, true)
alias vm_fence = () {
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
};

pragma(inline, true)
alias compiler_fence = () {
    asm {
        "" ::: "memory";
    }
};

/// Used to introduce happens-before edges between operations.
pragma(LDC_fence)
    void memory_fence(AtomicOrdering ordering = DefaultOrdering,
                      SynchronizationScope syncScope = SynchronizationScope.Default);


/// Atomically loads and returns a value from memory at ptr.
pragma(LDC_atomic_load)
    T atomic_load(T)(in shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

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

/// Atomically sets *ptr = val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "xchg")
    T atomic_rmw_xchg(T)(shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr += val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "add")
    T atomic_rmw_add(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr -= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "sub")
    T atomic_rmw_sub(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr &= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "and")
    T atomic_rmw_and(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = ~(*ptr & val) and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "nand")
    T atomic_rmw_nand(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr |= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "or")
    T atomic_rmw_or(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr ^= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "xor")
    T atomic_rmw_xor(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr > val ? *ptr : val) using a signed comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "max")
    T atomic_rmw_max(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr < val ? *ptr : val) using a signed comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "min")
    T atomic_rmw_min(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr > val ? *ptr : val) using an unsigned comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "umax")
    T atomic_rmw_umax(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr < val ? *ptr : val) using an unsigned comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "umin")
    T atomic_rmw_umin(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);
