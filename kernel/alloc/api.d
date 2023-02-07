module kernel.alloc.api;

import ulib.alloc;

import kernel.board;

// Allocation API.

// void* kalloc(size_t sz)
// T* knew(T, Args...)(Args args)
// T[] knew_array(T, Args...)(size_t nelem, Args args)
// void kfree(T)(T* ptr)

struct Alloc(A) {
    // Allocates a new block of `sz` bytes. Returns null if failed.
    static void* kalloc(A* allocator, size_t sz) {
        return allocator.alloc(sz);
    }

    // Allocates a new object of type T. Args passed to T.constructor. Returns
    // null if failed.
    static T* knew(T, Args...)(A* allocator, Args args) {
        T* p = cast(T*) allocator.alloc(T.sizeof);
        if (!p) {
            return null;
        }
        if (!emplace_init(p, args)) {
            allocator.free(p);
            return null;
        }
        return p;
    }

    // Allocates a new array of type T and of size nelem. Args passed to
    // T.constructor. Returns null if failed.
    static T[] knew_array(T, Args...)(A* allocator, size_t nelem, Args args) {
        T* p = cast(T*) allocator.alloc(T.sizeof * nelem);
        if (!p) {
            return null;
        }
        T[] arr = cast(T[]) p[0 .. nelem];
        for (int i = 0; i < arr.length; i++) {
            if (!emplace_init(&arr[i], args)) {
                allocator.free(p);
                return null;
            }
        }
        return arr;
    }

    // Calls the destructor for ptr and frees the memory.
    static void kfree(T)(A* allocator, T* ptr) {
        static if (HasDtor!T) {
            ptr.__xdtor();
        }
        allocator.free(cast(void*) ptr);
    }
}

// Allocation API using a custom allocator.

void* kalloc_custom(A)(A* allocator, size_t sz) {
    return Alloc!(A).kalloc(allocator, sz);
}

T* knew_custom(T, A, Args...)(A* allocator, Args args) {
    return Alloc!(A).knew!(T)(allocator, args);
}

T[] knew_array_custom(T, A, Args...)(A* allocator, size_t nelem, Args args) {
    return Alloc!(A).knew_array!(T)(allocator, args);
}

void kfree_custom(T, A)(A* allocator, T* ptr) {
    Alloc!(A).kfree!(T)(allocator, ptr);
}

// Allocation API using the system allocator.

alias SystemAlloc = Alloc!(typeof(System.allocator));

void* kalloc(size_t sz) {
    return SystemAlloc.kalloc(&System.allocator, sz);
}

T* knew(T, Args...)(Args args) {
    return SystemAlloc.knew!(T)(&System.allocator, args);
}

T[] knew_array(T, Args...)(size_t nelem, Args args) {
    return SystemAlloc.knew_array!(T)(&System.allocator, nelem, args);
}

void kfree(T)(T* ptr) {
    SystemAlloc.kfree(&System.allocator, ptr);
}

extern (C) {
    // C-like allocation API for ulib

    void* ulib_malloc(size_t sz) {
        return System.allocator.alloc(sz);
    }

    void ulib_free(void* p) {
        System.allocator.free(p);
    }
}
