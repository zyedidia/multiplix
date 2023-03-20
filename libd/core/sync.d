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
        import kernel.arch;
        version (kernel) version (check) Debug.vm_fence();
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

template DisableCheck() {
    const char[] DisableCheck = `
        version (check) {
            version (kernel) {
                import kernel.arch;
                bool en = Debug.disable();
                scope(exit) if (en) Debug.enable();
            }
        }
    `;
}

version (GNU) {
    enum MemoryOrder {
        /**
         * Not sequenced.
         * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#monotonic, LLVM AtomicOrdering.Monotonic)
         * and C++11/C11 `memory_order_relaxed`.
         */
        raw = 0,
        /**
         * Hoist-load + hoist-store barrier.
         * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#acquire, LLVM AtomicOrdering.Acquire)
         * and C++11/C11 `memory_order_acquire`.
         */
        acq = 2,
        /**
         * Sink-load + sink-store barrier.
         * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#release, LLVM AtomicOrdering.Release)
         * and C++11/C11 `memory_order_release`.
         */
        rel = 3,
        /**
         * Acquire + release barrier.
         * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#acquirerelease, LLVM AtomicOrdering.AcquireRelease)
         * and C++11/C11 `memory_order_acq_rel`.
         */
        acq_rel = 4,
        /**
         * Fully sequenced (acquire + release). Corresponds to
         * $(LINK2 https://llvm.org/docs/Atomics.html#sequentiallyconsistent, LLVM AtomicOrdering.SequentiallyConsistent)
         * and C++11/C11 `memory_order_seq_cst`.
         */
        seq = 5,
    }


    import gcc.builtins;
    void memory_fence() {
        __sync_synchronize();
    }

    void atomic_store(uint val, shared uint* ptr, MemoryOrder order = MemoryOrder.seq) {
        mixin(DisableCheck!());
        __atomic_store_4(ptr, val, order);
    }

    uint atomic_load(shared const uint* ptr, MemoryOrder order = MemoryOrder.seq) {
        mixin(DisableCheck!());
        return __atomic_load_4(ptr, order);
    }

    bool atomic_cmp_xchg(shared uint* ptr, uint cmp, uint val) {
        mixin(DisableCheck!());
        return __atomic_compare_exchange_4(ptr, &cmp, val, false, MemoryOrder.seq, MemoryOrder.seq);
    }

    uint lock_test_and_set(shared(uint*) lock, uint val) {
        mixin(DisableCheck!());
        return __sync_lock_test_and_set_4(lock, val);
    }

    void lock_release(shared(uint*) lock) {
        mixin(DisableCheck!());
        __sync_lock_release_4(lock);
    }

    T atomic_rmw_add(T)(in shared T* ptr, T val, MemoryOrder order = MemoryOrder.seq) {
        mixin(DisableCheck!());
        static if (is(T == ubyte) || is(T == byte)) {
            return cast(T) __atomic_add_fetch_1(cast(shared void*) ptr, cast(ubyte) val, order) - val;
        } else static if (is(T == ushort) || is(T == short)) {
            return cast(T) __atomic_add_fetch_2(cast(shared void*) ptr, cast(ushort) val, order) - val;
        } else static if (is(T == uint) || is(T == int)) {
            return cast(T) __atomic_add_fetch_4(cast(shared void*) ptr, cast(uint) val, order) - val;
        } else static if (is(T == ulong) || is(T == long)) {
            return cast(T) __atomic_add_fetch_8(cast(shared void*) ptr, cast(ulong) val, order) - val;
        } else {
            static assert(0, "atomic_rmw_add input is not an integer");
        }
    }

    T atomic_rmw_sub(T)(in shared T* ptr, T val, MemoryOrder order = MemoryOrder.seq) {
        mixin(DisableCheck!());
        static if (is(T == ubyte) || is(T == byte)) {
            return cast(T) __atomic_sub_fetch_1(cast(shared void*) ptr, cast(ubyte) val, order) - val;
        } else static if (is(T == ushort) || is(T == short)) {
            return cast(T) __atomic_sub_fetch_2(cast(shared void*) ptr, cast(ushort) val, order) - val;
        } else static if (is(T == uint) || is(T == int)) {
            return cast(T) __atomic_sub_fetch_4(cast(shared void*) ptr, cast(uint) val, order) - val;
        } else static if (is(T == ulong) || is(T == long)) {
            return cast(T) __atomic_sub_fetch_8(cast(shared void*) ptr, cast(ulong) val, order) - val;
        } else {
            static assert(0, "atomic_rmw_sub input is not an integer");
        }
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
        void _atomic_store(T)(T val, shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

    /// Atomically loads and returns a value from memory at ptr.
    pragma(LDC_atomic_load)
        T _atomic_load(T)(in shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

    void atomic_store(T, AtomicOrdering ordering = DefaultOrdering)(T val, shared T* ptr) {
        mixin(DisableCheck!());
        _atomic_store(val, ptr, ordering);
    }

    T atomic_load(T, AtomicOrdering ordering = DefaultOrdering)(in shared T* ptr) {
        mixin(DisableCheck!());
        return _atomic_load(ptr, ordering);
    }

    struct CmpXchgResult(T) {
        T previousValue;
        bool exchanged;
    }

    /// Loads a value from memory at ptr and compares it to cmp.
    /// If they are equal, it stores val in memory at ptr.
    /// This is all performed as single atomic operation.
    pragma(LDC_atomic_cmp_xchg)
        CmpXchgResult!T _atomic_cmp_xchg(T)(
            shared T* ptr, T cmp, T val,
            AtomicOrdering successOrdering = DefaultOrdering,
            AtomicOrdering failureOrdering = DefaultOrdering,
            bool weak = false);

    bool atomic_cmp_xchg(T)(shared T* ptr, T cmp, T val) {
        mixin(DisableCheck!());
        return _atomic_cmp_xchg(ptr, cmp, val).exchanged;
    }

    uint lock_test_and_set(shared(uint*) lock, uint val) {
        mixin(DisableCheck!());
        return _atomic_cmp_xchg(lock, 0, 1).previousValue;
    }

    void lock_release(shared(uint*) lock) {
        mixin(DisableCheck!());
        _atomic_store(0, lock);
    }

    /// Atomically sets *ptr += val and returns the previous *ptr value.
    pragma(LDC_atomic_rmw, "add")
        T _atomic_rmw_add(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);
    /// Atomically sets *ptr += val and returns the previous *ptr value.
    pragma(LDC_atomic_rmw, "sub")
        T _atomic_rmw_sub(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

    T atomic_rmw_add(T, AtomicOrdering ordering = DefaultOrdering)(in shared T* ptr, T val) {
        mixin(DisableCheck!());
        return _atomic_rmw_add(ptr, val, ordering);
    }

    T atomic_rmw_sub(T, AtomicOrdering ordering = DefaultOrdering)(in shared T* ptr, T val) {
        mixin(DisableCheck!());
        return _atomic_rmw_sub(ptr, val, ordering);
    }
}
