module plix.alloc;

import plix.alloc.buddy : BuddyAlloc;
import plix.alloc.block : BlockAlloc;
import plix.spinlock : SpinProtect;

import core.emplace : emplace_init, HasDtor;

private __gshared BuddyAlloc!(17) buddy;
private shared SpinProtect!(BlockAlloc!(typeof(buddy))) alloc;

void kallocinit(ubyte* heap_start, usize size) {
    auto alloc = alloc.lock();
    alloc.val.initialize(&buddy, heap_start[0 .. size]);
}

ubyte[] kalloc(usize sz) {
    auto alloc = alloc.lock();
    ubyte* p = cast(ubyte*) alloc.alloc(sz);
    if (!p) {
        return null;
    }
    return p[0 .. sz];
}

ubyte[] kzalloc(usize sz) {
    import builtins : memset;
    ubyte[] mem = kalloc(sz);
    if (!mem)
        return null;
    memset(mem.ptr, 0, mem.length);
    return mem;
}

T* knew(T)() {
    auto alloc = alloc.lock();
    T* p = cast(T*) alloc.alloc(T.sizeof);
    if (!p) {
        return null;
    }
    if (!emplace_init(p)) {
        alloc.free(cast(void*) p, T.sizeof);
        return null;
    }
    return p;
}

T[] kallocarray(T)(usize nelem) {
    auto alloc = alloc.lock();
    T* p = cast(T*) alloc.alloc(T.sizeof * nelem);
    if (!p) {
        return null;
    }
    return p[0 .. nelem];
}

void kfree(T)(T* ptr) if (is(T == struct)) {
    static if (HasDtor!(T)) {
        ptr.__xdtor();
    }
    auto alloc = alloc.lock();
    alloc.free(cast(void*) ptr, T.sizeof);
}

private void kfree(void* ptr, usize size) {
    auto alloc = alloc.lock();
    alloc.free(ptr, size);
}

void kfree(T)(T[] arr) {
    foreach (ref val; arr) {
        static if (HasDtor!(T)) {
            val.__xdtor();
        }
    }
    auto alloc = alloc.lock();
    alloc.free(cast(void*) arr.ptr, arr.length * T.sizeof);
}
