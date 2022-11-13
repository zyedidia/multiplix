module ulib.alloc;

import ulib.memory;

enum hasCtor(T) = __traits(hasMember, T, "__ctor");
enum hasDtor(T) = __traits(hasMember, T, "__dtor");

struct Bump(size_t alignment = 16) {
    static uintptr align_off(uintptr ptr, size_t algn) {
        return ((~ptr) + 1) & (algn - 1);
    }

    this(uintptr base, size_t size) {
        assert(base + size >= base);
        this.base = base;
        this.end = base + size;
        assert(this.base % alignment == 0);
        assert(this.end % alignment == 0);
    }

    void* allocPtr(size_t sz) {
        assert(sz + align_off(sz, alignment) >= sz);
        sz += align_off(sz, alignment);
        assert(base + sz >= base);
        if (base + sz >= end) {
            return null;
        }

        void* ptr = cast(void*) base;
        base += sz;
        return ptr;
    }

    void freePtr(void* ptr) {
        // no free
    }

private:
    uintptr base;
    uintptr end;
}

struct Kr(size_t alignment = 16) {
    this(uintptr base, size_t size) {
        bump = BumpAllocator(base, size);
    }

    void* allocPtr(size_t sz) {
        // TODO
        return null;
    }

    void freePtr(void* ptr) {
        // TODO
    }

private:
    Bump bump;
}

template emplaceInit(T, Args...) {
    immutable init = T.init;
    void emplaceInit(T* val, Args args) {
        static if (!is(T == struct)) {
            *val = T.init;
        } else {
            memcpy(val, &init, T.sizeof);
        }
        static if (hasCtor!T) {
            val.__ctor(args);
        }
    }
}

struct Allocator(A) {
    this(uintptr base, size_t size) {
        allocator = A(base, size);
    }

    T* make(T, Args...)(Args args) {
        T* val = cast(T*) allocator.allocPtr(T.sizeof);
        emplaceInit(val, args);
        return val;
    }

    void free(T)(T* val) {
        static if (hasDtor!T) {
            val.__dtor();
        }
        allocator.freePtr(cast(void*) val);
    }

    T[] makeArray(T, Args...)(size_t nelem, Args args) {
        T* p = cast(T*) allocator.allocPtr(T.sizeof * nelem);
        T[] arr = cast(T[]) p[0 .. nelem];
        for (int i = 0; i < arr.length; i++) {
            emplaceInit(&arr[i], args);
        }
        return arr;
    }

    void free(T)(T[] arr) {
        static if (hasDtor!T) {
            for (int i = 0; i < arr.length; i++) {
                arr[i].__dtor();
            }
        }
        allocator.freePtr(cast(void*) arr.ptr);
    }

private:
    A allocator;
}
