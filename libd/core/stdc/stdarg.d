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
    alias va_list = void*;

    pragma(LDC_va_start)
    void va_start(T)(out va_list ap, ref T parmn);

    pragma(LDC_va_end)
    void va_end(va_list ap);

    pragma(LDC_va_copy)
    void va_copy(out va_list dest, va_list src);

    pragma(LDC_va_arg)
    T va_arg(T)(ref va_list ap);
}
