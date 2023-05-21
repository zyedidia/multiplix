module core.memory;

static import builtins;
import core.math : min;

void mempcy(ubyte[] dst, ubyte[] src) {
    builtins.memcpy(dst.ptr, src.ptr, min(dst.length, src.length));
}

void memcpy(T)(T[] dst, T[] src) {
    foreach (i; 0 .. min(src.length, dst.length)) {
        dst[i] = src[i];
    }
}
