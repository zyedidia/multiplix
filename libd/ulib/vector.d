module ulib.vector;

import ulib.sys;
import ulib.memory;

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
        ulib_free(data.ptr);
        length = 0;
        data = null;
    }

    bool grow() {
        // double in size by default
        return grow(cap == 0 ? 8 : cap * 2);
    }

    bool grow(size_t newlen) {
        T* p = cast(T*) ulib_malloc(newlen * T.sizeof);
        if (!p) {
            return false;
        }
        memcpy(p, data.ptr, data.length * T.sizeof);
        ulib_free(data.ptr);
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
