module core.bitop;

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
}

version (LDC) {
    pragma(LDC_intrinsic, "ldc.bitop.vld") ubyte volatileLoad(ubyte* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") ushort volatileLoad(ushort* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") uint volatileLoad(uint* ptr);
    pragma(LDC_intrinsic, "ldc.bitop.vld") ulong volatileLoad(ulong* ptr);

    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatileStore(ubyte* ptr, ubyte value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatileStore(ushort* ptr, ushort value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatileStore(uint* ptr, uint value);
    pragma(LDC_intrinsic, "ldc.bitop.vst") void volatileStore(ulong* ptr, ulong value);
}
