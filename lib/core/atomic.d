module core.atomic;

version (GNU) {
    enum AtomicOrder {
        relaxed = 0,
        acquire = 2,
        release = 3,
        acqrel = 4,
        seqcst = 5,
    }

    import gcc.builtins;

    void atomic_fence(AtomicOrder order = AtomicOrder.seqcst) {
        __atomic_thread_fence(order);
    }

    void atomic_store(uint val, shared uint* ptr, AtomicOrder order = AtomicOrder.seqcst) {
        __atomic_store_4(ptr, val, order);
    }

    uint atomic_load(shared const uint* ptr, AtomicOrder order = AtomicOrder.seqcst) {
        return __atomic_load_4(ptr, order);
    }

    bool atomic_cmp_xchg(shared uint* ptr, uint cmp, uint val) {
        return __atomic_compare_exchange_4(ptr, &cmp, val, false, AtomicOrder.seqcst, AtomicOrder.seqcst);
    }

    ubyte atomic_test_and_set(shared(ubyte*) lock) {
        return __atomic_test_and_set(lock, AtomicOrder.acquire);
    }

    void atomic_clear(shared(ubyte*) lock) {
        __atomic_clear(lock, AtomicOrder.release);
    }

    T atomic_rmw_add(T, AtomicOrder order = AtomicOrder.seqcst)(in shared T* ptr, T val) {
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

    T atomic_rmw_sub(T, AtomicOrder order = AtomicOrder.seqcst)(in shared T* ptr, T val) {
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
    enum AtomicOrder {
        relaxed = 2,
        acquire = 4,
        release = 5,
        acqrel = 6,
        seqcst = 7,
    }

    enum SynchronizationScope {
        SingleThread = 0,
        CrossThread  = 1,
        Default = CrossThread
    }

    enum AtomicRmwSizeLimit = usize.sizeof;

    // Used to introduce happens-before edges between operations.
    pragma(LDC_fence)
        void atomic_fence(AtomicOrder ordering = AtomicOrder.seqcst,
                          SynchronizationScope syncScope = SynchronizationScope.Default);

    // Atomically stores val in memory at ptr.
    pragma(LDC_atomic_store)
        void _atomic_store(T)(T val, shared T* ptr, AtomicOrder ordering = AtomicOrder.seqcst);

    // Atomically loads and returns a value from memory at ptr.
    pragma(LDC_atomic_load)
        T _atomic_load(T)(in shared T* ptr, AtomicOrder ordering = AtomicOrder.seqcst);

    void atomic_store(T, AtomicOrder ordering = AtomicOrder.seqcst)(T val, shared T* ptr) {
        _atomic_store(val, ptr, ordering);
    }

    T atomic_load(T, AtomicOrder ordering = AtomicOrder.seqcst)(in shared T* ptr) {
        return _atomic_load(ptr, ordering);
    }

    struct CmpXchgResult(T) {
        T previousValue;
        bool exchanged;
    }

    // Loads a value from memory at ptr and compares it to cmp.
    // If they are equal, it stores val in memory at ptr.
    // This is all performed as single atomic operation.
    pragma(LDC_atomic_cmp_xchg)
        CmpXchgResult!T _atomic_cmp_xchg(T)(
            shared T* ptr, T cmp, T val,
            AtomicOrder successOrdering = AtomicOrder.seqcst,
            AtomicOrder failureOrdering = AtomicOrder.seqcst,
            bool weak = false);

    bool atomic_cmp_xchg(T)(shared T* ptr, T cmp, T val) {
        return _atomic_cmp_xchg(ptr, cmp, val).exchanged;
    }

    ubyte atomic_test_and_set(shared(ubyte*) lock) {
        return _atomic_cmp_xchg(lock, 0, 1, AtomicOrder.acquire, AtomicOrder.relaxed, true).previousValue;
    }

    void atomic_clear(shared(ubyte*) lock) {
        _atomic_store(0, lock, AtomicOrder.release);
    }

    // Atomically sets *ptr += val and returns the previous *ptr value.
    pragma(LDC_atomic_rmw, "add")
        T _atomic_rmw_add(T)(in shared T* ptr, T val, AtomicOrder ordering = AtomicOrder.seqcst);
    // Atomically sets *ptr += val and returns the previous *ptr value.
    pragma(LDC_atomic_rmw, "sub")
        T _atomic_rmw_sub(T)(in shared T* ptr, T val, AtomicOrder ordering = AtomicOrder.seqcst);

    T atomic_rmw_add(T, AtomicOrder ordering = AtomicOrder.seqcst)(in shared T* ptr, T val) {
        return _atomic_rmw_add(ptr, val, ordering);
    }

    T atomic_rmw_sub(T, AtomicOrder ordering = AtomicOrder.seqcst)(in shared T* ptr, T val) {
        return _atomic_rmw_sub(ptr, val, ordering);
    }
}
