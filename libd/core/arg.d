module core.arg;

version (GNU) {
    import gcc.builtins;
    alias va_list = __builtin_va_list;
    alias va_end = __builtin_va_end;
    alias va_copy = __builtin_va_copy;

    void va_start(T)(out va_list ap, ref T parmn);
    T va_arg(T)(ref va_list ap);
    void va_arg(T)(ref va_list ap, ref T parmn);
} else version (LDC) {
    version (RISCV_Any) {
        alias va_list = void*;
    } else {
        alias va_list = char*;
    }

    pragma(LDC_va_start)
    void va_start(T)(out va_list ap, ref T parmn);

    pragma(LDC_va_end)
    void va_end(va_list ap);

    pragma(LDC_va_copy)
    void va_copy(out va_list dest, va_list src);

    // TODO: implementations for va_arg
}
