module core.atomic;

nothrow:
@nogc:

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

/// Used to introduce happens-before edges between operations.
pragma(LDC_fence)
    void llvm_memory_fence(AtomicOrdering ordering = DefaultOrdering,
                           SynchronizationScope syncScope = SynchronizationScope.Default);

/// Atomically loads and returns a value from memory at ptr.
pragma(LDC_atomic_load)
    T llvm_atomic_load(T)(in shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

/// Atomically stores val in memory at ptr.
pragma(LDC_atomic_store)
    void llvm_atomic_store(T)(T val, shared T* ptr, AtomicOrdering ordering = DefaultOrdering);

struct CmpXchgResult(T) {
    T previousValue;
    bool exchanged;
}

/// Loads a value from memory at ptr and compares it to cmp.
/// If they are equal, it stores val in memory at ptr.
/// This is all performed as single atomic operation.
pragma(LDC_atomic_cmp_xchg)
    CmpXchgResult!T llvm_atomic_cmp_xchg(T)(
        shared T* ptr, T cmp, T val,
        AtomicOrdering successOrdering = DefaultOrdering,
        AtomicOrdering failureOrdering = DefaultOrdering,
        bool weak = false);

/// Atomically sets *ptr = val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "xchg")
    T llvm_atomic_rmw_xchg(T)(shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr += val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "add")
    T llvm_atomic_rmw_add(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr -= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "sub")
    T llvm_atomic_rmw_sub(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr &= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "and")
    T llvm_atomic_rmw_and(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = ~(*ptr & val) and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "nand")
    T llvm_atomic_rmw_nand(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr |= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "or")
    T llvm_atomic_rmw_or(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr ^= val and returns the previous *ptr value.
pragma(LDC_atomic_rmw, "xor")
    T llvm_atomic_rmw_xor(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr > val ? *ptr : val) using a signed comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "max")
    T llvm_atomic_rmw_max(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr < val ? *ptr : val) using a signed comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "min")
    T llvm_atomic_rmw_min(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr > val ? *ptr : val) using an unsigned comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "umax")
    T llvm_atomic_rmw_umax(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);

/// Atomically sets *ptr = (*ptr < val ? *ptr : val) using an unsigned comparison.
/// Returns the previous *ptr value.
pragma(LDC_atomic_rmw, "umin")
    T llvm_atomic_rmw_umin(T)(in shared T* ptr, T val, AtomicOrdering ordering = DefaultOrdering);
