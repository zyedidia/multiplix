module kernel.alloc;

import ulib.option;

Opt!(void*) kallocpage(size_t sz) {
    return Opt!(void*)(null);
}

Opt!(void*) kallocpage() {
    return Opt!(void*)(null);
}

import ulib.alloc;

Opt!(T*) kalloc(T)() {
    return Opt!(T*)(null);
}

void kfree(void* ptr) {
}
