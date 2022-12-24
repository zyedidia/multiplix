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

    ubyte volatile_ld(ubyte* ptr) {
        return volatileLoad(ptr);
    }
    ushort volatile_ld(ushort* ptr) {
        return volatileLoad(ptr);
    }
    uint volatile_ld(uint* ptr) {
        return volatileLoad(ptr);
    }
    ulong volatile_ld(ulong* ptr) {
        return volatileLoad(ptr);
    }

    void volatile_st(ubyte* ptr, ubyte value) {
        volatileStore(ptr, value);
    }
    void volatile_st(ushort* ptr, ushort value) {
        volatileStore(ptr, value);
    }
    void volatile_st(uint* ptr, uint value) {
        volatileStore(ptr, value);
    }
    void volatile_st(ulong* ptr, ulong value) {
        volatileStore(ptr, value);
    }
}

version (LDC) {
    pragma(LDC_intrinsic, "ldc.bitop.vld") ubyte volatile_ld(ubyte* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") ushort volatile_ld(ushort* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") uint volatile_ld(uint* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") ulong volatile_ld(ulong* ptr);

    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatile_st(ubyte* ptr, ubyte value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatile_st(ushort* ptr, ushort value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatile_st(uint* ptr, uint value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatile_st(ulong* ptr, ulong value);
}

