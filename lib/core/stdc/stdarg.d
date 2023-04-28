module core.stdc.stdarg;

// It would be nice to put this in core.arg instead, but we have to put it in
// core.stdc.stdarg so that GDC will replace the builtins properly.

version (GNU) {
    import gcc.builtins;
    alias va_list = __builtin_va_list;
    alias va_end = __builtin_va_end;
    alias va_copy = __builtin_va_copy;

    void va_start(T)(out va_list ap, ref T parmn);
    T va_arg(T)(ref va_list ap);
    void va_arg(T)(ref va_list ap, ref T parmn);
} else version (LDC) {

    pragma(LDC_va_start)
    void va_start(T)(out va_list ap, ref T parmn);

    pragma(LDC_va_end)
    void va_end(va_list ap);

    pragma(LDC_va_copy)
    void va_copy(out va_list dest, va_list src);

    // Here va_arg implementations for riscv and aarch64 (from druntime). Fall
    // back to LLVM va_arg intrinsic (which is quite broken and unused).
    version (RISCV64) {
        alias va_list = void*;

        T va_arg(T)(ref va_list ap) {
            static if (T.sizeof > (size_t.sizeof << 1))
                auto p = *cast(T**) ap;
            else {
                static if (T.alignof == (size_t.sizeof << 1))
                    ap = ap.alignUp!(size_t.sizeof << 1);
                auto p = cast(T*) ap;
            }
            ap += T.sizeof.alignUp;
            return *p;
        }
    } else version (AArch64) {
        extern (C++, std) struct __va_list {
            void* __stack;
            void* __gr_top;
            void* __vr_top;
            int __gr_offs;
            int __vr_offs;
        }

        alias va_list = __va_list;

        T va_arg(T)(ref va_list ap) {
            static if (is(T ArgTypes == __argTypes)) {
                T onStack() {
                    void* arg = ap.__stack;
                    static if (T.alignof > 8)
                        arg = arg.alignUp!16;
                    ap.__stack = alignUp(arg + T.sizeof);
                    version (BigEndian)
                        static if (T.sizeof < 8)
                        arg += 8 - T.sizeof;
                    return *cast(T*) arg;
                }

                static if (ArgTypes.length == 0) {
                    // indirectly by value; get pointer and copy
                    T* ptr = va_arg!(T*)(ap);
                    return *ptr;
                }

                static assert(ArgTypes.length == 1);

                static if (is(ArgTypes[0] E : E[N], int N))
                    alias FundamentalType = E; // static array element type
                else
                    alias FundamentalType = ArgTypes[0];

                static if (__traits(isFloating, FundamentalType) || is(FundamentalType == __vector)) {
                    // SIMD register(s)
                    int offs = ap.__vr_offs;
                    if (offs >= 0)
                        return onStack();           // reg save area empty
                    enum int usedRegSize = FundamentalType.sizeof;
                    static assert(T.sizeof % usedRegSize == 0);
                    enum int nreg = T.sizeof / usedRegSize;
                    ap.__vr_offs = offs + (nreg * 16);
                    if (ap.__vr_offs > 0)
                        return onStack();           // overflowed reg save area
                    version (BigEndian)
                        static if (usedRegSize < 16)
                        offs += 16 - usedRegSize;

                    T result = void;
                    static foreach (i; 0 .. nreg)
                        memcpy((cast(void*) &result) + i * usedRegSize, ap.__vr_top + (offs + i * 16), usedRegSize);
                    return result;
                } else {
                    // GP register(s)
                    int offs = ap.__gr_offs;
                    if (offs >= 0)
                        return onStack();           // reg save area empty
                    static if (T.alignof > 8)
                        offs = offs.alignUp!16;
                    enum int nreg = (T.sizeof + 7) / 8;
                    ap.__gr_offs = offs + (nreg * 8);
                    if (ap.__gr_offs > 0)
                        return onStack();           // overflowed reg save area
                    version (BigEndian)
                        static if (T.sizeof < 8)
                        offs += 8 - T.sizeof;
                    return *cast(T*) (ap.__gr_top + offs);
                }
            } else {
                static assert(false, "not a valid argument type for va_arg");
            }
        }
    } else {
        pragma(msg, "warning: using LLVM va_arg builtin (known to have bugs)");
        alias va_list = void*;
        // Use the built-in va_arg intrinsic, which is sparsely supported and
        // has bugs in LLVM.
        pragma(LDC_va_arg)
        T va_arg(T)(ref va_list ap);
    }

    T alignUp(size_t alignment = size_t.sizeof, T)(T base) pure {
        enum mask = alignment - 1;
        static assert(alignment > 0 && (alignment & mask) == 0, "alignment must be a power of 2");
        auto b = cast(size_t) base;
        b = (b + mask) & ~mask;
        return cast(T) b;
    }
}
