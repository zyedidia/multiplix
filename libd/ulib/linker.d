module ulib.linker;

template LinkerVar(string name) {
    const char[] LinkerVar = "extern (C) extern __gshared char " ~ name ~ ";\n" ~
        "uintptr " ~ name ~ "_addr() { return cast(uintptr) &" ~ name ~ "; }";
}
