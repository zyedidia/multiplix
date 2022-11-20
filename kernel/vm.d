module kernel.vm;

import sys = kernel.sys;

uintptr ka2pa(uintptr ka) {
    return ka - sys.highmemBase;
}

uintptr pa2ka(uintptr pa) {
    return pa + sys.highmemBase;
}
