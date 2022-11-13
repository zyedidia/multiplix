module ulib.trait;

template Unqual(T : const U, U) {
    static if (is(U == shared V, V))
        alias Unqual = V;
    else
        alias Unqual = U;
}

static assert(is(Unqual!int == int));
static assert(is(Unqual!(const int) == int));
static assert(is(Unqual!(immutable int) == int));
static assert(is(Unqual!(shared int) == int));
static assert(is(Unqual!(shared(const int)) == int));

enum isInt8(T) = is(Unqual!T == byte) || is(Unqual!T == ubyte);
enum isInt16(T) = is(Unqual!T == short) || is(Unqual!T == ushort);
enum isInt32(T) = is(Unqual!T == int) || is(Unqual!T == uint);
enum isInt64(T) = is(Unqual!T == long) || is(Unqual!T == ulong);
enum isInt(T) = isInt8!T || isInt16!T || isInt32!T || isInt64!T;
