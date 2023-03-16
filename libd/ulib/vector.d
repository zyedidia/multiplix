module ulib.vector;

import kernel.alloc;

import ulib.sys;
import libc;

struct Vector(T) {
    T[] data;
    size_t length;

    T[] array() {
        return data[0 .. length];
    }

    ref T opIndex(size_t i) {
        assert(i < length, "vector index out of bounds");
        return data[i];
    }

    size_t cap() {
        return data.length;
    }

    void clear() {
        kfree(data.ptr);
        length = 0;
        data = null;
    }

    bool grow() {
        // double in size by default
        return grow(cap == 0 ? 8 : cap * 2);
    }

    bool grow(size_t newlen) {
        T* p = cast(T*) kalloc(newlen * T.sizeof);
        if (!p) {
            return false;
        }
        memcpy(p, data.ptr, data.length * T.sizeof);
        kfree(data.ptr);
        data = cast(T[]) p[0 .. newlen];
        return true;
    }

    bool append(T value) {
        if (!data || length >= cap) {
            if (!grow()) {
                return false;
            }
        }
        assert(length < cap);
        data[length++] = value;
        return true;
    }

    Range!T range() {
        return Range!T(0, this);
    }

    void unordered_remove(size_t idx) {
        assert(idx < length, "vector index out of bounds");
        data[idx] = data[length - 1];
        length--;
    }

    alias range this;

    struct Range(T) {
        size_t i;
        Vector!(T) vec;

        bool empty() {
            return i >= vec.length;
        }

        ref T front() {
            return vec[i];
        }

        void popFront() {
            i++;
        }
    }
}
