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
