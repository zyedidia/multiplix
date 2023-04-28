module core.trait;

template Unqual(T : const U, U) {
    static if (is(U == shared V, V))
        alias Unqual = V;
    else
        alias Unqual = U;
}

enum isi8(T) = is(Unqual!T == byte) || is(Unqual!T == ubyte);
enum isi16(T) = is(Unqual!T == short) || is(Unqual!T == ushort);
enum isi32(T) = is(Unqual!T == int) || is(Unqual!T == uint);
enum isi64(T) = is(Unqual!T == long) || is(Unqual!T == ulong);
enum isint(T) = isi8!T || isi16!T || isi32!T || isi64!T;

enum isptr(T) = is(T == U*, U) && __traits(isScalar, T);

// Get return type of a function.
template ReturnType(func...) if (func.length == 1) {
    static if (is(func[0] R == return)) {
        alias ReturnType = R;
    }
}
