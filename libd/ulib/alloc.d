module ulib.alloc;

import ulib.memory;
import ulib.bits;

enum HasCtor(T) = __traits(hasMember, T, "__ctor");
enum HasDtor(T) = __traits(hasMember, T, "__dtor");

uintptr align_off(uintptr ptr, size_t algn) {
    return ((~ptr) + 1) & (algn - 1);
}

struct Bump(size_t alignment = 16) {
    this(uintptr base, size_t size) {
        assert(base + size >= base);
        this.base = base;
        this.end = base + size;
        assert(this.base % alignment == 0);
        assert(this.end % alignment == 0);
    }

    void* alloc_ptr(size_t sz) {
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

    void free_ptr(void* ptr) {
        // no free
    }

private:
    uintptr base;
    uintptr end;
}

template emplace_init(T, Args...) {
    immutable init = T.init;
    void emplace_init(T* val, Args args) {
        static if (!is(T == struct)) {
            *val = T.init;
        } else {
            memcpy(val, &init, T.sizeof);
        }
        static if (HasCtor!T) {
            val.__ctor(args);
        }
    }
}

struct Allocator(A) {
    this(uintptr heap_start) {
        allocator = A(heap_start);
    }

    T* make(T, Args...)(Args args) {
        T* val = cast(T*) allocator.alloc_ptr(T.sizeof);
        if (val == null) {
            return null;
        }
        emplace_init(val, args);
        return val;
    }

    void free(T)(T* val) {
        static if (HasDtor!T) {
            val.__dtor();
        }
        allocator.free_ptr(cast(void*) val);
    }

    T[] make_array(T, Args...)(size_t nelem, Args args) {
        T* p = cast(T*) allocator.alloc_ptr(T.sizeof * nelem);
        T[] arr = cast(T[]) p[0 .. nelem];
        for (int i = 0; i < arr.length; i++) {
            emplace_init(&arr[i], args);
        }
        return arr;
    }

    void free(T)(T[] arr) {
        static if (HasDtor!T) {
            for (int i = 0; i < arr.length; i++) {
                arr[i].__dtor();
            }
        }
        allocator.free_ptr(cast(void*) arr.ptr);
    }

private:
    A allocator;
}
