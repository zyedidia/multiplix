module plix.alloc;

import plix.alloc.kr : KrAlloc;
import plix.spinlock : SpinGuard;

import core.emplace : emplace_init, HasDtor;

private shared SpinGuard!(KrAlloc!(16)) kr;

void kallocinit(ubyte* heap_start, usize size) {
    auto kr = kr.lock();
    kr.val.__ctor(heap_start, size);
}

ubyte[] kalloc(usize sz) {
    auto kr = kr.lock();
    ubyte* p = cast(ubyte*) kr.alloc(sz);
    if (!p) {
        return null;
    }
    return p[0 .. sz];
}

T* knew(T, Args...)(Args args) {
    auto kr = kr.lock();
    T* p = cast(T*) kr.alloc(T.sizeof);
    if (!p) {
        return null;
    }
    if (!emplace_init(p, args)) {
        kr.free(p);
        return null;
    }
    return p;
}

void kfree(T)(T* ptr) {
    static if (HasDtor!(T)) {
        ptr.__xdtor();
    }
    auto kr = kr.lock();
    kr.free(cast(void*) p);
}
