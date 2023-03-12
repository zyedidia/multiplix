module core.builtins;

version (LDC) {
    pragma(LDC_intrinsic, "llvm.returnaddress")
        void* llvm_returnaddress(uint level);

    alias return_address = llvm_returnaddress;
} else version (GNU) {
    import gcc.builtins;
    alias return_address = __builtin_return_address;
}
