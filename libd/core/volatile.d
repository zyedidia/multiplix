module core.volatile;

nothrow:
@safe:
@nogc:

version (GNU) {
    ubyte volatileLoad(ubyte* ptr);
    ushort volatileLoad(ushort* ptr);
    uint volatileLoad(uint* ptr);
    ulong volatileLoad(ulong* ptr);

    void volatileStore(ubyte* ptr, ubyte value);
    void volatileStore(ushort* ptr, ushort value);
    void volatileStore(uint* ptr, uint value);
    void volatileStore(ulong* ptr, ulong value);

    ubyte vld(ubyte* ptr) {
        return volatileLoad(ptr);
    }
    ushort vld(ushort* ptr) {
        return volatileLoad(ptr);
    }
    uint vld(uint* ptr) {
        return volatileLoad(ptr);
    }
    ulong vld(ulong* ptr) {
        return volatileLoad(ptr);
    }

    void vst(ubyte* ptr, ubyte value) {
        volatileStore(ptr, value);
    }
    void vst(ushort* ptr, ushort value) {
        volatileStore(ptr, value);
    }
    void vst(uint* ptr, uint value) {
        volatileStore(ptr, value);
    }
    void vst(ulong* ptr, ulong value) {
        volatileStore(ptr, value);
    }
}

version (LDC) {
    pragma(LDC_intrinsic, "ldc.bitop.vld") ubyte vld(ubyte* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") ushort vld(ushort* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") uint vld(uint* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") ulong vld(ulong* ptr);

    pragma(LDC_intrinsic, "ldc.bitop.vst") void vst(ubyte* ptr, ubyte value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void vst(ushort* ptr, ushort value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void vst(uint* ptr, uint value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void vst(ulong* ptr, ulong value);
}

